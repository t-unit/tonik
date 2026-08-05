def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

if (context.request.path == '/api/v1/widget' && context.request.method == 'GET') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/vnd.api+json')
        .withContent('{"id":42,"name":"sprocket"}')

} else if (context.request.path == '/api/v1/problem' && context.request.method == 'GET') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/problem+json')
        .withContent('{"id":7,"name":"teapot"}')

} else if (context.request.path == '/api/v1/wildcard/application' && context.request.method == 'GET') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"id":99,"name":"application-wildcard"}')

} else if (context.request.path == '/api/v1/wildcard/catch-all' && context.request.method == 'GET') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'text/plain')
        .withContent('catch-all wildcard response')

} else {
    respond().usingDefaultBehaviour()
}
