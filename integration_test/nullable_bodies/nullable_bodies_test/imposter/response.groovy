// Serve a JSON `null` body when the caller asks for it via X-Winner, so the
// same nullable-string endpoint can exercise both a null and a non-null body.
def wantNull = (context.request.headers['X-Winner'] ?: '') == 'null'
def path = context.request.path

if (path == '/winner/inline' || path == '/winner/ref') {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent(wantNull ? 'null' : '"alice"')
} else {
    respond().usingDefaultBehaviour()
}
