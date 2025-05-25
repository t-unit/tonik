// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'

// Set the response status code and use the OpenAPI specification
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))

if (context.request.path == '/api/v3/user/login' && responseStatus == '200') {
    // For login endpoint with 200 status, return a properly formatted JSON string
    response.withHeader('Content-Type', 'application/json')
          .withContent('"example return value"')

} else {
    // For all other cases, use default behavior
    response.usingDefaultBehaviour()
} 