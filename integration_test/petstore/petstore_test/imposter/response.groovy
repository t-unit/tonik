// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'

// Set the response status code and use the OpenAPI specification
respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .withDefaultBehaviour() 