def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

// Imposter response script for Shopify Admin API integration tests.

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent '{"errors": "Mock error"}'
    }
    return
}

// ── Success responses ──────────────────────────────────────────────────

respond {
    withStatusCode statusCode
}
