// Echo the request path back in the response body for path encoding validation
def requestPath = context.request.path ?: ''
def requestMethod = context.request.method ?: 'GET'

respond()
    .withStatusCode(200)
    .withHeader('Content-Type', 'application/json')
    .withContent("""{"path": "${requestPath}", "method": "${requestMethod}"}""")
