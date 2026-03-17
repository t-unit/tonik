// Imposter response script for Asana API integration tests.
//
// Handles two issues with the Imposter OpenAPI plugin:
// 1. Error status codes don't get Content-Type: application/json
// 2. Complex schemas produce invalid auto-generated data

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────
// Asana uses: {"errors": [{"message": "...", "help": "..."}]}

if (statusCode >= 400) {
    def body = '{"errors": [{"message": "Mock error", "help": "https://developers.asana.com"}]}'

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200/201 responses ───────────────────────────────────────────
// Note: Imposter prepends the server base path /api/1.0 from the Asana spec.
// Asana wraps all responses in {"data": ...} envelope.

// Reusable workspace object
def workspace = '{"gid": "12345", "resource_type": "workspace", "name": "My Workspace"}'

// GET /api/1.0/workspaces
if (path == '/api/1.0/workspaces' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": [${workspace}]}"""
    }
    return
}

// GET /api/1.0/workspaces/{workspaceGid}
if (path.matches('/api/1.0/workspaces/[^/]+') && !path.matches('/api/1.0/workspaces/[^/]+/.+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${workspace}}"""
    }
    return
}

// Reusable user object
def user = '{"gid": "67890", "resource_type": "user", "name": "Test User"}'

// GET /api/1.0/users
if (path == '/api/1.0/users' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": [${user}]}"""
    }
    return
}

// Reusable task object
def task = '{"gid": "11111", "resource_type": "task", "name": "Test Task"}'

// GET /api/1.0/tasks/{taskGid}
if (path.matches('/api/1.0/tasks/[^/]+') && !path.matches('/api/1.0/tasks/[^/]+/.+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${task}}"""
    }
    return
}

// PUT /api/1.0/tasks/{taskGid}
if (path.matches('/api/1.0/tasks/[^/]+') && !path.matches('/api/1.0/tasks/[^/]+/.+') && context.request.method == 'PUT') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${task}}"""
    }
    return
}

// DELETE /api/1.0/tasks/{taskGid}
if (path.matches('/api/1.0/tasks/[^/]+') && !path.matches('/api/1.0/tasks/[^/]+/.+') && context.request.method == 'DELETE') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"data": {}}'
    }
    return
}

// POST /api/1.0/tasks
if (path == '/api/1.0/tasks' && context.request.method == 'POST') {
    respond {
        withStatusCode 201
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${task}}"""
    }
    return
}

// Reusable project object
def project = '{"gid": "22222", "resource_type": "project", "name": "Test Project"}'

// GET /api/1.0/projects/{projectGid}
if (path.matches('/api/1.0/projects/[^/]+') && !path.matches('/api/1.0/projects/[^/]+/.+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${project}}"""
    }
    return
}

// GET /api/1.0/projects/{projectGid}/tasks
if (path.matches('/api/1.0/projects/[^/]+/tasks') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": [${task}]}"""
    }
    return
}

// POST /api/1.0/workspaces/{workspaceGid}/projects
if (path.matches('/api/1.0/workspaces/[^/]+/projects') && context.request.method == 'POST') {
    respond {
        withStatusCode 201
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": ${project}}"""
    }
    return
}

// GET /api/1.0/workspaces/{workspaceGid}/tasks/search
if (path.matches('/api/1.0/workspaces/[^/]+/tasks/search') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"data": [${task}]}"""
    }
    return
}

// ── Default responses ──────────────────────────────────────────────────

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
