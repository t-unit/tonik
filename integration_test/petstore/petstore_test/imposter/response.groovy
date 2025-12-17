// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'

// Set the response status code and use the OpenAPI specification
def response = respond()
    .withStatusCode(Integer.parseInt(responseStatus))

if (context.request.path == '/api/v3/user/login' && responseStatus == '200') {
    // For login endpoint with 200 status, return a properly formatted JSON string
    response.withHeader('Content-Type', 'application/json')
          .withContent('"example return value"')

} else if (context.request.path.matches('/api/v3/pet/\\d+/health') && responseStatus == '200') {
    // For pet health endpoint with 200 status, return RFC 7807 Problem Details JSON
    def petId = context.request.path.replaceAll('.*/pet/(\\d+)/health', '$1')
    response.withHeader('Content-Type', 'application/problem+json')
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

} else {
    // For all other cases, use default behavior
    response.usingDefaultBehaviour()
} 