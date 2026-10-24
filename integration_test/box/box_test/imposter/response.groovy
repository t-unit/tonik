def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

if (statusCode == 404) {
    respond {
        withStatusCode 404
        withHeader 'Content-Type', 'application/json'
        withContent '{"type":"error","status":404,"code":"not_found","message":"Restriction not found","request_id":"request-42"}'
    }
    return
}

// Pin a schema-valid keyword card for the response's four-way oneOf.
if (context.request.path.matches('/2.0/files/[^/]+/metadata/global/boxSkillsCards')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"$canEdit":true,"$version":2,"cards":[{"type":"skill_card","skill_card_type":"keyword","skill":{"type":"service","id":"image-labels"},"invocation":{"type":"skill_invocation","id":"invocation-42"},"entries":[{"text":"landscape"}]}]}'
    }
    return
}

// Let the OpenAPI plugin produce the declared empty DELETE response.
respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
