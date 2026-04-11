// Get the response status from the request header (case-insensitive for Windows compatibility)
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Set the response status code and use the OpenAPI specification
respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .usingDefaultBehaviour()
