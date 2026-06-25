def response = respond().withStatusCode(200)

if (context.request.path == '/api/v1/widget' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'application/vnd.api+json')
            .withContent('{"id":42,"name":"sprocket"}')

} else if (context.request.path == '/api/v1/problem' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'application/problem+json')
            .withContent('{"id":7,"name":"teapot"}')

} else {
    response.usingDefaultBehaviour()
}
