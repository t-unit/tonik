import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

def path = context.request.path
def method = context.request.method

def slurper = new JsonSlurper()

// POST /users: augment response with server-generated readOnly fields,
// strip writeOnly fields (simulates real server behavior).
if (path == '/users' && method == 'POST' && statusCode == 200) {
    def body = slurper.parseText(context.request.body)
    body.id = 42
    body.createdAt = '2025-01-01T00:00:00Z'
    body.remove('password')
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent(JsonOutput.toJson(body))

// GET /users/{id}: return a fixed user with readOnly fields.
} else if (path ==~ '/users/\\d+' && method == 'GET' && statusCode == 200) {
    def userId = path.tokenize('/').last() as int
    def body
    if (userId == 99) {
        body = [id: 99, name: 'Bob', email: 'bob@example.com', createdAt: '2025-06-15T12:00:00Z']
    } else {
        body = [id: userId, name: 'Alice', createdAt: '2025-01-01T00:00:00Z']
    }
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent(JsonOutput.toJson(body))

// POST /credentials: acknowledge without echoing writeOnly data.
} else if (path == '/credentials' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"status":"created"}')

// POST /audit-entry: return a fixed audit entry with all readOnly fields.
} else if (path == '/audit-entry' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"entryId":1,"timestamp":"2025-01-01T10:00:00Z","action":"login"}')

// GET /notifications/sent: return a readOnly oneOf notification (email variant).
} else if (path == '/notifications/sent' && method == 'GET' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"emailAddress":"alice@example.com","subject":"Welcome","body":"Hello!"}')

// POST /notifications/send: accept a writeOnly oneOf notification and echo status.
} else if (path == '/notifications/send' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"status":"accepted"}')

// GET /server-info: return a readOnly allOf server info response.
} else if (path == '/server-info' && method == 'GET' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"serverId":"srv-001","region":"us-east","cpuUsage":42.5,"memoryUsage":75.0}')

// POST /bulk-command: accept a writeOnly allOf bulk command.
} else if (path == '/bulk-command' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent('{"status":"executed"}')

} else if (method == 'POST' && statusCode == 200) {
    def requestBody = context.request.body
    respond()
        .withStatusCode(statusCode)
        .withHeader('Content-Type', 'application/json')
        .withContent(requestBody)
} else {
    respond()
        .withStatusCode(statusCode)
        .usingDefaultBehaviour()
}
