// Get the response status from the request header
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// Add required headers based on endpoint and status code
def path = context.request.path
def method = context.request.method

// Authentication endpoints
if (path == '/auth/login' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Set-Cookie', 'session=test-session-token; Path=/; HttpOnly; Secure; SameSite=Strict')
        .withHeader('X-Api-Commit', 'abc123def456')
        .usingDefaultBehaviour()
} else if (path == '/auth/logout' && method == 'POST' && statusCode == 204) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Set-Cookie', 'session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT')
        .withHeader('X-Api-Commit', 'abc123def456')
        .usingDefaultBehaviour()
}

// Event ping endpoint (path may include query parameters)
else if (path.startsWith('/event/ping') && method == 'GET' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'text/plain')
        .withHeader('Last-Modified', 'Thu, 09 Jan 2026 00:00:00 GMT')
        .withHeader('Cache-Control', 'max-age=86400')
        .withHeader('X-Api-Commit', 'abc123def456')
        .withContent('OK')
        .usingDefaultBehaviour()
}

// For all other responses, use default behavior
else {
    respond()
        .withStatusCode(statusCode)
        .usingDefaultBehaviour()
}
