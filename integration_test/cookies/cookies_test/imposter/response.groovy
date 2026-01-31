// Get the response status from the request header (case-insensitive for compatibility)
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Echo back the Cookie header for verification in tests
def cookieHeader = headers['Cookie'] ?: headers['cookie'] ?: ''

// Set the response status code and use the OpenAPI specification
respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .withHeader('X-Received-Cookie', cookieHeader)
    .usingDefaultBehaviour()
