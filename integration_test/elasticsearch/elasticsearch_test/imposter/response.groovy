// Imposter 4.9.3's Swagger ResolverFully overflows on recursive schemas.
// Follow the existing REST fixture pattern; Tonik still generates the full spec.

def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

if (context.request.path == '/_stats') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"_shards":{"failed":0,"successful":2,"total":2},"_all":{"uuid":"aggregate"},"indices":{"products":{"uuid":"index-42"}}}'
    }
    return
}

// The upstream examples are JSON strings; return JSON objects for both requests.
if (context.request.path == '/_security/api_key/_bulk_update') {
    def requestBody = new groovy.json.JsonSlurper().parseText(context.request.body)
    def body = requestBody.ids instanceof List
        ? '{"updated":["key-a","key-b"],"noops":[]}'
        : '{"updated":[],"noops":["key-a"]}'
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

respond()
    .withStatusCode(200)
    .usingDefaultBehaviour()
