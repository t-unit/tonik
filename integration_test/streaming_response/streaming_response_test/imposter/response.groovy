def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

def headers = context.request.headers
def responseCase = headers['X-Response-Case'] ?: headers['x-response-case'] ?: ''
def contentType = 'application/x-ndjson'
def statusCode = 200
def count = '1'
def body

switch (context.request.path) {
    case '/items':
        if (responseCase == 'malformed') {
            body = 'invalid\n{"value":2}\n'
        } else if (responseCase == 'invalid-model') {
            body = '{"value":"bad"}\n{"value":2}\n'
        } else {
            body = '{"value":1}\n{"value":2}\n'
        }
        break
    case '/jsonl':
        contentType = 'application/jsonl'
        body = '{"value":3}\r \n{"value":4}'
        break
    case '/sse-data':
        contentType = 'text/event-stream; charset=utf-8'
        body = 'data: {"value":1}\r\n\r\ndata: café\ndata: second line\n\n'
        break
    case '/sse-fields':
        contentType = 'text/event-stream'
        body = 'event: update\nid: 7\nretry: 0010\ndata: one\ndata: two\n\nevent:\nid:\ndata\n\ndata: last\n\n'
        break
    case '/sse-required-event':
        contentType = 'text/event-stream'
        body = 'event: ready\ndata: first\n\ndata: missing event\n\nevent: later\ndata: third\n\n'
        break
    case '/ordinary':
        contentType = 'application/json'
        body = '{"value":9}'
        break
    case '/mixed':
        switch (responseCase) {
            case 'json':
                contentType = 'application/json'
                body = '{"value":9}'
                break
            case 'empty':
                statusCode = 204
                body = ''
                break
            case 'bad-request':
                statusCode = 400
                contentType = 'application/json'
                body = '"invalid request"'
                break
            case 'range':
                statusCode = 202
                body = '{"value":2}\n'
                break
            case 'default':
                statusCode = 418
                contentType = 'application/json'
                body = '"teapot"'
                break
            case 'malformed':
                body = 'invalid\n{"value":2}\n'
                break
            default:
                count = '2'
                body = '{"value":1}\n{"value":2}\n'
        }
        break
    case '/aliased-stream':
        if (responseCase == 'invalid-header') count = 'invalid'
        body = '{"value":6}\n'
        break
    case '/profiles':
        if (responseCase == 'other-profile') {
            contentType = 'application/x-ndjson; profile=other'
            body = '1\n'
        } else {
            contentType = 'application/x-ndjson; charset=utf-8; profile="detail"'
            body = '{"value":4}\n'
        }
        break
    case '/referenced-stream':
        body = '{"value":11}\n{"value":12}\n'
        break
    case '/referenced-mixed':
        if (responseCase == 'json') {
            contentType = 'application/json'
            body = '{"value":14}'
        } else if (responseCase == 'external') {
            contentType = 'application/jsonl'
            body = '1\n2\n'
        } else {
            body = '{"value":13}\n'
        }
        break
    case '/schema-only':
        body = '1\n2\n'
        break
    case '/referenced-request':
        contentType = 'application/json'
        body = '{"value":15}'
        break
    case '/nullable-items':
        body = '1\nnull\n2\n'
        break
    case '/any-items':
        body = 'null\n3\n"text"\ntrue\n[1]\n{"key":2}\n'
        break
    case '/never-items':
        body = responseCase == 'invalid-item' ? 'null\n1\n' : ''
        break
    case '/nested-items':
        body = '[{"value":4,"metrics":{"scores":[2,3]}}]\n[]\n'
        break
    case '/events':
        if (responseCase == 'json') {
            contentType = 'application/json'
            body = '{"total":3}'
        } else if (responseCase == 'invalid-union') {
            body = '{"kind":"state","progress":25}\n{"kind":"result","result":42}\n{"kind":"result","result":"unreachable"}\n'
        } else {
            body = '{"kind":"state","progress":25}\n{"kind":"error","message":"try again"}\n{"kind":"result","result":"finished"}\n'
        }
        break
    case '/alternative-items':
        if (responseCase == 'jsonl') {
            contentType = 'application/jsonl'
            body = '{"label":"named"}\n'
        } else if (responseCase == 'accepted') {
            statusCode = 202
            body = '{"ready":true}\n'
        } else {
            body = '{"count":5}\n'
        }
        break
    default:
        throw new IllegalArgumentException('Unexpected fixture path: ' + context.request.path)
}

respond {
    withStatusCode statusCode
    withHeader 'Content-Type', contentType
    withHeader 'X-Count', count
    withHeader 'X-Stream', 'imposter'
    withContent body
}
