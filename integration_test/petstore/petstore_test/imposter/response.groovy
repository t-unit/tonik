// Get the response status from the request header (case-insensitive for Windows compatibility)
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Set the response status code and use the OpenAPI specification
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .usingDefaultBehaviour()

// Override specific endpoints that need custom responses (without resetting default behavior)
if (context.request.path == '/api/v3/user/login' && responseStatus == '200') {
    // For login endpoint with 200 status, return a properly formatted JSON string
    response = respond()
        .withStatusCode(Integer.parseInt(responseStatus))
        .withHeader('Content-Type', 'application/json')
        .withContent('"example return value"')

} else if (context.request.path.matches('/api/v3/pet/\\d+/health') && responseStatus == '200') {
    // For pet health endpoint with 200 status, return RFC 7807 Problem Details
    // JSON. The Content-Type carries `version=1` and `charset=utf-8` parameters
    // to exercise tolerant media-type matching on the generated client.
    def petId = context.request.path.replaceAll('.*/pet/(\\d+)/health', '$1')
    response = respond()
        .withStatusCode(Integer.parseInt(responseStatus))
        .withHeader('Content-Type', 'application/problem+json; version=1; charset=utf-8')
        .withContent("""
            {
              "type": "https://example.com/probs/pet-health",
              "title": "Pet Health Report",
              "status": 200,
              "detail": "Health report for pet ${petId}",
              "petId": ${petId},
              "healthStatus": "healthy"
            }
          """.trim())
} else if (context.request.path.matches('/api/v3/pet/\\d+') && context.request.method == 'GET' && responseStatus == '200') {
    // Sends `Content-Type: application/json; charset=utf-8` so the generated
    // client must extract the bare media type before matching the case arm.
    def petId = context.request.path.replaceAll('.*/pet/(\\d+)', '$1')
    response = respond()
        .withStatusCode(Integer.parseInt(responseStatus))
        .withHeader('Content-Type', 'application/json; charset=utf-8')
        .withContent("""
            {
              "id": ${petId},
              "name": "doggie",
              "photoUrls": ["https://example.com/photo.png"]
            }
          """.trim())
}