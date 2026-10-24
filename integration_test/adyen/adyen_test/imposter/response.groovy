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

// Supply a deterministic JSON error; successful responses use upstream examples.
if (statusCode == 403) {
    respond {
        withStatusCode 403
        withHeader 'Content-Type', 'application/json'
        withContent '{"detail":"Insufficient permissions","errorCode":"010","status":403,"title":"Forbidden","type":"https://errors.example/forbidden"}'
    }
    return
}

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
