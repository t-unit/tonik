def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

if (context.request.path == '/streamed-tag-groups') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/x-ndjson')
        .withContent('[{"primary":["alpha","beta"]}]\n[]\n')
    return
}

// Get the response status from the request header (case-insensitive for Windows compatibility)
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

// Set the response status code and use the OpenAPI specification
respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .usingDefaultBehaviour()
