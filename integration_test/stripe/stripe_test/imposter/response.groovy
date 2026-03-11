// Imposter response script for Stripe API integration tests.
//
// Handles two issues with the Imposter OpenAPI plugin:
// 1. Error status codes don't get Content-Type: application/json
// 2. Complex schemas produce invalid auto-generated data

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────
// Stripe uses a wrapped error format: {"error": {"type": "...", "message": "..."}}
// Return proper JSON error bodies matching the Stripe API Error schema.

if (statusCode >= 400) {
    def body = """{"error": {"type": "api_error", "message": "Mock error"}}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses for complex schemas ───────────────────────────
// Endpoints with complex nested schemas need hand-crafted JSON because
// Imposter's auto-generated examples are often invalid.

// GET /v1/balance — use empty arrays to avoid BalanceAmount.currency BigDecimal bug
if (path == '/v1/balance') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"available": [], "livemode": false, "object": "balance", "pending": []}'
    }
    return
}

// GET /v1/customers
if (path == '/v1/customers' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"data": [], "has_more": false, "object": "list", "url": "/v1/customers"}'
    }
    return
}

// POST /v1/customers
if (path == '/v1/customers' && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"created": 1234567890, "id": "cus_mock", "livemode": false, "object": "customer"}'
    }
    return
}

// GET /v1/customers/{customer}
if (path.matches('/v1/customers/[^/]+') && !path.contains('/balance') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"created": 1234567890, "id": "cus_mock", "livemode": false, "object": "customer"}'
    }
    return
}

// DELETE /v1/customers/{customer}
if (path.matches('/v1/customers/[^/]+') && context.request.method == 'DELETE') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"deleted": true, "id": "cus_mock", "object": "customer"}'
    }
    return
}

// GET /v1/charges
if (path == '/v1/charges' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"data": [], "has_more": false, "object": "list", "url": "/v1/charges"}'
    }
    return
}

// GET /v1/payment_intents/{intent}
if (path.matches('/v1/payment_intents/[^/]+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"created": 1234567890, "id": "pi_mock", "livemode": false, "object": "payment_intent", "status": "succeeded"}'
    }
    return
}

// POST /v1/refunds
if (path == '/v1/refunds' && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"amount": 1000, "created": 1234567890, "currency": "840", "id": "re_mock", "object": "refund"}'
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────
// Let Imposter generate responses from the OpenAPI spec for simple schemas.

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
