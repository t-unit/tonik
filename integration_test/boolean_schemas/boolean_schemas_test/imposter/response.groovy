import groovy.json.JsonSlurper
import groovy.json.JsonOutput

// Get the response status from the request header
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Set the response status code
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))

// Echo endpoints - return request body as response
if (context.request.path.endsWith('/echo')) {
    def contentType = context.request.headers['Content-Type'] ?: 'application/json'
    
    if (contentType?.contains('application/json')) {
        response.withHeader('Content-Type', 'application/json')
              .withContent(context.request.body ?: '{}')
    } else if (contentType?.contains('application/x-www-form-urlencoded')) {
        response.withHeader('Content-Type', 'application/x-www-form-urlencoded')
              .withContent(context.request.body ?: '')
    } else {
        response.withContent(context.request.body ?: '')
    }
} else if (context.request.path == '/json/any' || 
           context.request.path == '/json/any-array' ||
           context.request.path == '/json/never' ||
           context.request.path == '/json/pure-any' ||
           context.request.path == '/json/pure-never') {
    // Echo back JSON body for all JSON endpoints
    response.withHeader('Content-Type', 'application/json')
          .withContent(context.request.body ?: '{}')
} else if (context.request.path == '/form/any' || context.request.path == '/form/never') {
    // Echo back form body
    response.withHeader('Content-Type', 'application/x-www-form-urlencoded')
          .withContent(context.request.body ?: '')
} else if (context.request.path == '/response/any') {
    // Return a sample ObjectWithAny
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([
              name: 'test',
              anyData: [nested: [1, 2, 3], flag: true],
              optionalAny: 'optional value',
              metadata: [version: 1]
          ]))
} else if (context.request.path == '/response/any-array') {
    // Return a sample FlexibleArray
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([
              'string',
              123,
              true,
              null,
              [nested: 'object'],
              [1, 2, 3]
          ]))
} else if (context.request.path == '/response/never') {
    // Return response with never field (omitted as it's impossible to provide)
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([neverField: null]))
} else if (context.request.path == '/response/headers') {
    // Return response with custom headers containing any values
    // Note: X-Never-Header is NOT set, as NeverModel does not permit any value
    response.withHeader('Content-Type', 'application/json')
          .withHeader('X-Any-Header', 'any-header-value')
          .withContent(JsonOutput.toJson([status: 'ok']))
} else if (context.request.path.contains('/path/any/') || 
           context.request.path.contains('/path/any-explode/') ||
           context.request.path.contains('/path/label/any') ||
           context.request.path.contains('/path/matrix/any') ||
           context.request.path.contains('/path/never/') ||
           context.request.path.contains('/path/list-any/') ||
           context.request.path.contains('/path/list-any-explode/') ||
           context.request.path.contains('/path/label/list-any') ||
           context.request.path.contains('/path/matrix/list-any')) {
    // Extract path parameter and return it
    def pathValue = context.request.path.split('/').last()
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: pathValue]))
} else if (context.request.path == '/query/any' || 
           context.request.path == '/query/any-no-explode' ||
           context.request.path == '/query/space-delimited/any' ||
           context.request.path == '/query/space-delimited/any-explode' ||
           context.request.path == '/query/pipe-delimited/any' ||
           context.request.path == '/query/pipe-delimited/any-explode' ||
           context.request.path == '/query/deep-object/any' ||
           context.request.path == '/query/never') {
    // Extract query parameter and return it
    def queryValue = context.request.queryParams['anyValue'] ?: 
                     context.request.queryParams['neverValue'] ?: ''
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: queryValue]))
} else if (context.request.path == '/query/list-any') {
    // For explode=true, values come as repeated query params
    // Parse from the raw query string
    def rawUri = context.request.uri ?: ''
    def queryPart = rawUri.contains('?') ? rawUri.substring(rawUri.indexOf('?') + 1) : ''
    def values = []
    queryPart.split('&').each { param ->
        if (param.startsWith('anyValues=')) {
            values.add(URLDecoder.decode(param.substring('anyValues='.length()), 'UTF-8'))
        }
    }
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: values]))
} else if (context.request.path == '/query/list-any-no-explode' ||
           context.request.path == '/query/space-delimited/list-any' ||
           context.request.path == '/query/pipe-delimited/list-any') {
    // For explode=false, value is comma-separated string
    def queryValue = context.request.queryParams['anyValues'] ?: ''
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: queryValue]))
} else if (context.request.path == '/header/any' || 
           context.request.path == '/header/any-explode' ||
           context.request.path == '/header/never' ||
           context.request.path == '/header/list-any' ||
           context.request.path == '/header/list-any-explode') {
    // Extract header value and return it
    def headerValue = context.request.headers['X-Any-Value'] ?: 
                      context.request.headers['X-Any-Values'] ?: 
                      context.request.headers['X-Never-Value'] ?: ''
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: headerValue]))
} else if (context.request.path.startsWith('/combined/')) {
    // Extract all parameter values
    def pathValue = context.request.path.split('/').last()
    def queryValue = context.request.queryParams['queryAny'] ?: ''
    def headerValue = context.request.headers['X-Header-Any'] ?: ''
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([
              pathValue: pathValue,
              queryValue: queryValue,
              headerValue: headerValue
          ]))
} else if (context.request.path == '/query/object-with-list-any' ||
           context.request.path == '/query/deep-object/object-with-list-any') {
    // Extract object query parameters and return them
    def receivedParams = [:]
    context.request.queryParams.each { key, value ->
        receivedParams[key] = value
    }
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([received: receivedParams]))
} else if (context.request.path == '/form/list-any') {
    // Echo back form data status
    response.withHeader('Content-Type', 'application/json')
          .withContent(JsonOutput.toJson([status: 'ok']))
} else {
    // For all other cases, use default behavior
    response.usingDefaultBehaviour()
}
