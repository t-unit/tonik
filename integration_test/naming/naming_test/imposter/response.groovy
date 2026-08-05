def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

if (context.request.path == '/response-body-collision/header-normalized') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withHeader('body_', 'header-value')
        .withContent('{"id":"body-value"}')
    return
}

respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .usingDefaultBehaviour()
