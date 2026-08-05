def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

// Get the response status from the request header
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Set the response status code and prepare the response
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))

// Echo all request headers as response headers
context.request.headers.each { name, value ->
    response.withHeader(name, value)
}

// Use the OpenAPI specification for default behavior
response.usingDefaultBehaviour()
