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

if (statusCode == 404) {
    respond {
        withStatusCode 404
        withHeader 'Content-Type', 'application/json'
        withContent '{"id":"not_found","message":"Default project not found","request_id":"request-42"}'
    }
    return
}

// This response has no upstream example; use a non-empty vector database object.
if (context.request.path.matches('/v2/vector-databases/[^/]+/resize')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"vector_db":{"id":"vector-42","name":"Product search"}}'
    }
    return
}

// Keep the upstream project example and pin its rate-limit response header.
respond()
    .withStatusCode(statusCode)
    .withHeader('ratelimit-limit', '5000')
    .usingDefaultBehaviour()
