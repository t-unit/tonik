// Get the response status from the request header
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path
def method = context.request.method

// Handle 422 responses with proper HTTPValidationError body
if (statusCode == 422) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"detail":[{"loc":["body","field_name"],"msg":"field required","type":"value_error.missing"}]}')
}
// Handle send_message endpoints - return ChatMessageBody example (one of the oneOf options)
else if (path.contains('/infer/send_message') && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"body":{"GUID":"msg-guid-123","text":"Hello, this is a response"},"confidence":0.95,"element_type":"text"}')
}
// Handle list_connectors endpoint - return array of objects
else if (path == '/api/v1/infer/list_connectors' && method == 'GET' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('[{"connector_name":"Deductive AI","connector_type":"DEDUCTIVE_NATIVE"},{"connector_name":"prometheus","connector_type":"PROMETHEUS"}]')
}
// Handle supported_models endpoint - return array of strings
else if (path == '/api/v1/infer/supported_models' && method == 'GET' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('["gpt-4o","claude-3.7-sonnet","gemini-pro"]')
}
else {
    // Use default behavior based on OpenAPI spec examples for other responses
    respond()
        .withStatusCode(statusCode)
        .usingDefaultBehaviour()
}
