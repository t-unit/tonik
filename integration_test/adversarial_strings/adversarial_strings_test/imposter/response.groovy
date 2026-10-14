def tonikRecordedRequest = [
    uri: context.request.uri,
    method: context.request.method,
    normalisedHeaders: context.request.normalisedHeaders,
    body: context.request.body,
]
stores.open('tonik').save('last', tonikRecordedRequest)

if (context.request.uri.endsWith('/quoted-media-alternatives')) {
    respond()
        .withStatusCode(200)
        .withHeader('Content-Type', context.request.normalisedHeaders['content-type'])
        .withContent(context.request.body)
        .skipDefaultBehaviour()
} else if (context.request.uri.endsWith('/quoted-content-type')) {
    respond()
        .withStatusCode(418)
        .withHeader('Content-Type', 'text/plain; charset=utf-8')
        .skipDefaultBehaviour()
} else {
    respond()
        .withStatusCode(204)
        .skipDefaultBehaviour()
}
