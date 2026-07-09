def response = respond().withStatusCode(200)

if (context.request.path == '/api/v1/widget' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'application/vnd.api+json')
            .withContent('{"id":42,"name":"sprocket"}')

} else if (context.request.path == '/api/v1/problem' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'application/problem+json')
            .withContent('{"id":7,"name":"teapot"}')

} else if (context.request.path == '/api/v1/wildcard/application' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'application/json')
            .withContent('{"id":99,"name":"application-wildcard"}')

} else if (context.request.path == '/api/v1/wildcard/catch-all' && context.request.method == 'GET') {
    response.withHeader('Content-Type', 'text/plain')
            .withContent('catch-all wildcard response')

} else if (context.request.path == '/api/v1/wildcard/range-status' && context.request.method == 'GET') {
    response.withStatusCode(206)
            .withHeader('Content-Type', 'application/json')
            .withContent('{"id":206,"name":"range-wildcard"}')

} else {
    response.usingDefaultBehaviour()
}
