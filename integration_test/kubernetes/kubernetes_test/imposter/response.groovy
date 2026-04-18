// Imposter response script for Kubernetes API integration tests.

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    def body = """{"kind": "Status", "apiVersion": "v1", "metadata": {}, "status": "Failure", "message": "Mock error", "code": ${statusCode}}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses ───────────────────────────────────────────────

if (path == '/api/v1/namespaces' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"kind": "NamespaceList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": []}'
    }
    return
}

if (path == '/api/v1/pods' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"kind": "PodList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": []}'
    }
    return
}

if (path == '/api/v1/services' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"kind": "ServiceList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": []}'
    }
    return
}

if (path == '/api/v1/configmaps' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"kind": "ConfigMapList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": []}'
    }
    return
}

// GET /api/v1/namespaces/{namespace}/configmaps
if (path.matches('/api/v1/namespaces/[^/]+/configmaps') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"kind": "ConfigMapList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": []}'
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
