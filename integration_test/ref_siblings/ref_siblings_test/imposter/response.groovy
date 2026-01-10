// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// Echo-style responses: return the request body as the response
// This allows us to verify that encoding and decoding work correctly
def path = context.request.path
def method = context.request.method

// For POST endpoints, echo back the request body
if (method == 'POST' && statusCode == 200) {
    def requestBody = context.request.body
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent(requestBody)
} else {
    // For all other cases, use default behavior
    respond()
        .withStatusCode(statusCode)
        .usingDefaultBehaviour()
}
