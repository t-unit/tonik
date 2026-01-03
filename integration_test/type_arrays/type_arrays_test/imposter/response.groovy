// Imposter response script for type arrays tests
def path = context.request.path

// For POST endpoints, echo back the request body as JSON
if (path == '/simple-types' || 
    path == '/nullable-types' || 
    path == '/composition' || 
    path == '/edge-cases') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent(context.request.body ?: '{}')
} else if (path == '/health') {
    // Health endpoint returns specific response
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"status":"ok"}')
} else if (path.startsWith('/top-level/')) {
    // Top-level type array returns a string variant
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('"test-value"')
} else {
    // For other methods, use default OpenAPI behavior
    respond().usingDefaultBehaviour()
}
