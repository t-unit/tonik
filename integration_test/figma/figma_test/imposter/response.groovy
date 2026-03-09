// Imposter response script for Figma API integration tests.
//
// Handles two issues with the Imposter OpenAPI plugin:
// 1. Error status codes don't get Content-Type: application/json
// 2. Complex oneOf/anyOf schemas produce invalid auto-generated data

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────
// Imposter doesn't set Content-Type for non-200 responses. Return proper
// JSON error bodies matching the Figma API error schemas.

if (statusCode >= 400) {
    // Figma uses two error formats depending on endpoint+status:
    //   ErrorBoolean: { "error": true, "status": N, "message": "..." }
    //   ErrMessage:   { "status": N, "err": "..." }
    // Include both sets of fields so either parser succeeds.
    def body = """{"error": true, "status": ${statusCode}, "message": "Mock error", "err": "Mock error"}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses for complex schemas ───────────────────────────
// Endpoints with oneOf in the response schema need hand-crafted JSON
// because Imposter's auto-generated examples are often invalid.

// Activity logs – contains ActivityLog items with oneOf entity
if (path == '/v1/activity_logs') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"status": 200, "error": false, "meta": {"activity_logs": [], "cursor": "", "next_page": false}}'
    }
    return
}

// Library analytics component actions
if (path.matches('.*/analytics/libraries/.*/component/actions')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// Library analytics component usages
if (path.matches('.*/analytics/libraries/.*/component/usages')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// Library analytics style actions
if (path.matches('.*/analytics/libraries/.*/style/actions')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// Library analytics style usages
if (path.matches('.*/analytics/libraries/.*/style/usages')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// Library analytics variable actions
if (path.matches('.*/analytics/libraries/.*/variable/actions')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// Library analytics variable usages
if (path.matches('.*/analytics/libraries/.*/variable/usages')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"rows": [], "next_page": false}'
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────
// Let Imposter generate responses from the OpenAPI spec for simple schemas.

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
