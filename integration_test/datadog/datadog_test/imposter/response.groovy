def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// Error responses need an explicit JSON media type and deterministic body.
if (statusCode == 404) {
    respond {
        withStatusCode 404
        withHeader 'Content-Type', 'application/json'
        withContent '{"errors":["Signal not found"]}'
    }
    return
}

// Successful responses use the examples from the complete upstream spec.
respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
