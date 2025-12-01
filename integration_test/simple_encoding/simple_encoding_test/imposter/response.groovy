// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'

// Set the response status code and prepare the response
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))

// Echo all request headers as response headers
context.request.headers.each { name, value ->
    response.withHeader(name, value)
}

// Use the OpenAPI specification for default behavior
response.usingDefaultBehaviour()
