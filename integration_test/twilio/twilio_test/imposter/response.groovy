// Imposter response script for Twilio API integration tests.

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    def body = """{"code": 20001, "message": "Mock error", "status": ${statusCode}}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── DELETE operations return 204 No Content ────────────────────────────

if (context.request.method == 'DELETE') {
    respond {
        withStatusCode 204
    }
    return
}

// ── Custom 200/201 responses ───────────────────────────────────────────

// GET /2010-04-01/Accounts.json
if (path == '/2010-04-01/Accounts.json' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"accounts": [], "end": 0, "first_page_uri": "/2010-04-01/Accounts.json?PageSize=50&Page=0", "next_page_uri": null, "page": 0, "page_size": 50, "previous_page_uri": null, "start": 0, "uri": "/2010-04-01/Accounts.json?PageSize=50&Page=0"}'
    }
    return
}

// POST /2010-04-01/Accounts.json
if (path == '/2010-04-01/Accounts.json' && context.request.method == 'POST') {
    respond {
        withStatusCode 201
        withHeader 'Content-Type', 'application/json'
        withContent '{"sid": "AC_mock", "friendly_name": "Mock Account", "status": "active", "type": "Full", "date_created": "Thu, 01 Jan 2026 00:00:00 +0000", "date_updated": "Thu, 01 Jan 2026 00:00:00 +0000", "auth_token": "mock_token", "uri": "/2010-04-01/Accounts/AC_mock.json"}'
    }
    return
}

// GET /2010-04-01/Accounts/{Sid}.json
if (path.matches('/2010-04-01/Accounts/[^/]+\\.json') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"sid": "AC_mock", "friendly_name": "Mock Account", "status": "active", "type": "Full", "date_created": "Thu, 01 Jan 2026 00:00:00 +0000", "date_updated": "Thu, 01 Jan 2026 00:00:00 +0000", "auth_token": "mock_token", "uri": "/2010-04-01/Accounts/AC_mock.json"}'
    }
    return
}

// GET /2010-04-01/Accounts/{AccountSid}/Messages.json
if (path.matches('/2010-04-01/Accounts/[^/]+/Messages\\.json') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"messages": [], "end": 0, "first_page_uri": "/2010-04-01/Accounts/AC_mock/Messages.json?PageSize=50&Page=0", "next_page_uri": null, "page": 0, "page_size": 50, "previous_page_uri": null, "start": 0, "uri": "/2010-04-01/Accounts/AC_mock/Messages.json?PageSize=50&Page=0"}'
    }
    return
}

// POST /2010-04-01/Accounts/{AccountSid}/Messages.json
if (path.matches('/2010-04-01/Accounts/[^/]+/Messages\\.json') && context.request.method == 'POST') {
    respond {
        withStatusCode 201
        withHeader 'Content-Type', 'application/json'
        withContent '{"sid": "SM_mock", "account_sid": "AC_mock", "to": "+15558675310", "from": "+15017122661", "body": "Hello", "status": "queued", "direction": "outbound-api", "date_created": "Thu, 01 Jan 2026 00:00:00 +0000", "date_updated": "Thu, 01 Jan 2026 00:00:00 +0000", "uri": "/2010-04-01/Accounts/AC_mock/Messages/SM_mock.json"}'
    }
    return
}

// GET /2010-04-01/Accounts/{AccountSid}/Calls.json
if (path.matches('/2010-04-01/Accounts/[^/]+/Calls\\.json') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"calls": [], "end": 0, "first_page_uri": "/2010-04-01/Accounts/AC_mock/Calls.json?PageSize=50&Page=0", "next_page_uri": null, "page": 0, "page_size": 50, "previous_page_uri": null, "start": 0, "uri": "/2010-04-01/Accounts/AC_mock/Calls.json?PageSize=50&Page=0"}'
    }
    return
}

// GET /2010-04-01/Accounts/{AccountSid}/Balance.json
if (path.matches('/2010-04-01/Accounts/[^/]+/Balance\\.json') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"account_sid": "AC_mock", "balance": "100.00", "currency": "USD"}'
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
