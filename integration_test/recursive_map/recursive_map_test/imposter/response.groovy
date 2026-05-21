// Imposter response script for the recursive-map integration tests.
//
// GET endpoints return deterministic JSON exercising the generated
// `_decode<Type>` helper. POST endpoints accept the recursive body and
// echo the raw request body back as an `X-Echo-Body` response header so
// the test can verify the `_encode<Type>` helper produces the expected
// shape — POST per the spec returns 204 (no body), so the round-trip
// must travel through a header.

import java.util.Base64

def path = context.request.path
def method = context.request.method

// Echoes the request body as a base64 X-Echo-Body header on a 204
// response. POST endpoints in the spec return 204 No Content; the
// generated client expects 204, so we keep the status code spec-faithful
// and surface the echoed body out-of-band.
def echo204() {
    def bodyStr = context.request.body ?: ''
    def encoded = Base64.encoder.encodeToString(bodyStr.getBytes('UTF-8'))
    respond()
        .withStatusCode(204)
        .withHeader('X-Echo-Body', encoded)
        .withEmpty()
}

if (method == 'GET' && path.endsWith('/tree')) {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('''{"a":{"b":{"c":{}}},"d":{}}''')
    return
}

if (method == 'POST' && path.endsWith('/tree')) {
    echo204()
    return
}

if (method == 'GET' && path.endsWith('/forest')) {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('''[[[]],[]]''')
    return
}

if (method == 'POST' && path.endsWith('/forest')) {
    echo204()
    return
}

if (method == 'GET' && path.endsWith('/node')) {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('''{"id":"root","subtree":{"left":{"leaf":{}},"right":{}}}''')
    return
}

if (method == 'POST' && path.endsWith('/node')) {
    echo204()
    return
}

if (method == 'GET' && path.endsWith('/aMap')) {
    // AMap → Map<String, BMap>; BMap → Map<String, AMap>. One nesting
    // level demonstrates the indirect cycle is decoded as a single helper
    // pair.
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', 'application/json')
        .withContent('''{"b":{"a":{}}}''')
    return
}

if (method == 'POST' && path.endsWith('/aMap')) {
    echo204()
    return
}

// Fallback: default OpenAPI behaviour for any unhandled paths.
respond().usingDefaultBehaviour()
