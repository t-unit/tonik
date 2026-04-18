// Imposter response script for Cloudflare API integration tests.
//
// Uses the REST plugin (not OpenAPI) because the Cloudflare spec is too
// large for Imposter's OpenAPI plugin (duplicate path params crash Vert.x).

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    def body = """{"success": false, "errors": [{"code": ${statusCode}, "message": "Mock error"}], "messages": [], "result": null}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses ───────────────────────────────────────────────

// GET /client/v4/accounts
if (path == '/client/v4/accounts' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"success": true, "errors": [], "messages": [], "result": [], "result_info": {"page": 1, "per_page": 20, "count": 0, "total_count": 0}}'
    }
    return
}

// GET /client/v4/zones
if (path == '/client/v4/zones' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"success": true, "errors": [], "messages": [], "result": [], "result_info": {"page": 1, "per_page": 20, "count": 0, "total_count": 0}}'
    }
    return
}

// ── Default ────────────────────────────────────────────────────────────

respond {
    withStatusCode statusCode
    withHeader 'Content-Type', 'application/json'
    withContent '{"success": true, "errors": [], "messages": [], "result": null}'
}
