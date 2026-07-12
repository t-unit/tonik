// Tests drive the exact response body (e.g. a whole-number double like 42.0)
// through the X-Response-Body header so they can assert how the client decodes
// numeric JSON forms that jsonDecode materializes as a Dart double.
def headers = context.request.headers
def body = headers['X-Response-Body'] ?: headers['x-response-body']

if (context.request.path.endsWith('/echo') && body != null) {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent(body)
} else {
    respond().usingDefaultBehaviour()
}
