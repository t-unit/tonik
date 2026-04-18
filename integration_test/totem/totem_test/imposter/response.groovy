// Imposter response script for Totem Mobile API integration tests.

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent """{"error": "Mock error", "status": ${statusCode}}"""
    }
    return
}

// ── DELETE returns boolean ─────────────────────────────────────────────

if (context.request.method == 'DELETE') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent 'true'
    }
    return
}

// ── Default: let Imposter generate responses from the spec ─────────────

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
