// Get the response status from the request header
def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def responseCharsetCase = headers['X-Response-Charset-Case'] ?: headers['x-response-charset-case']
def statusCode = Integer.parseInt(responseStatus)

// Add required headers based on endpoint and status code
def path = context.request.path
def method = context.request.method

// Authentication endpoints
if (path == '/auth/login' && method == 'POST' && statusCode == 200) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Set-Cookie', 'session=test-session-token; Path=/; HttpOnly; Secure; SameSite=Strict')
        .withHeader('X-Api-Commit', 'abc123def456')
        .usingDefaultBehaviour()
} else if (path == '/auth/logout' && method == 'POST' && statusCode == 204) {
    respond()
        .withStatusCode(statusCode)
        .withHeader('Set-Cookie', 'session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT')
        .withHeader('X-Api-Commit', 'abc123def456')
        .usingDefaultBehaviour()
}

// Event ping endpoint (path may include query parameters)
else if (path.startsWith('/event/ping') && method == 'GET' && statusCode == 200) {
    def response = respond()
        .withStatusCode(statusCode)
        .withHeader('Last-Modified', 'Thu, 09 Jan 2026 00:00:00 GMT')
        .withHeader('Cache-Control', 'max-age=86400')
        .withHeader('X-Api-Commit', 'abc123def456')

    def charsetResponses = [
        'utf8-default': [contentType: 'text/plain', file: 'charset-fixtures/utf8.bin'],
        'utf8-alias': [contentType: 'text/plain; charset=utf8', file: 'charset-fixtures/utf8.bin'],
        'quoted-uppercase-utf8': [contentType: 'Text/Plain; Charset="UTF-8"', file: 'charset-fixtures/utf8.bin'],
        'us-ascii': [contentType: 'text/plain; charset=us-ascii', file: 'charset-fixtures/ascii.bin'],
        'iso-8859-1': [contentType: 'text/plain; charset=iso-8859-1', file: 'charset-fixtures/iso-8859-1.bin'],
        'iso-8859-15': [contentType: 'text/plain; charset=iso-8859-15', file: 'charset-fixtures/iso-8859-15.bin'],
        'windows-1252': [contentType: 'text/plain; charset=windows-1252', file: 'charset-fixtures/windows-1252.bin'],
        'windows-1251': [contentType: 'text/plain; charset=windows-1251', file: 'charset-fixtures/windows-1251.bin'],
        'shift-jis': [contentType: 'text/plain; charset=shift_jis', file: 'charset-fixtures/shift-jis.bin'],
        'windows-31j': [contentType: 'text/plain; charset=windows-31j', file: 'charset-fixtures/shift-jis.bin'],
        'euc-jp': [contentType: 'text/plain; charset=euc-jp', file: 'charset-fixtures/euc-jp.bin'],
        'euc-kr': [contentType: 'text/plain; charset=euc-kr', file: 'charset-fixtures/euc-kr.bin'],
        'cp949': [contentType: 'text/plain; charset=cp949', file: 'charset-fixtures/euc-kr.bin'],
        'gbk': [contentType: 'text/plain; charset=gbk', file: 'charset-fixtures/gbk.bin'],
        'x-gbk': [contentType: 'text/plain; charset=x-gbk', file: 'charset-fixtures/gbk.bin'],
        'utf-16': [contentType: 'text/plain; charset=utf-16', file: 'charset-fixtures/utf-16.bin'],
        'utf-16le': [contentType: 'text/plain; charset=utf-16le', file: 'charset-fixtures/utf-16le.bin'],
        'utf-16be': [contentType: 'text/plain; charset=utf-16be', file: 'charset-fixtures/utf-16be.bin'],
        'utf-32': [contentType: 'text/plain; charset=utf-32', file: 'charset-fixtures/utf-32.bin'],
        'utf-32le': [contentType: 'text/plain; charset=utf-32le', file: 'charset-fixtures/utf-32le.bin'],
        'utf-32be': [contentType: 'text/plain; charset=utf-32be', file: 'charset-fixtures/utf-32be.bin'],
        'unsupported': [contentType: 'text/plain; charset=made-up', file: 'charset-fixtures/ascii.bin'],
        'gb18030': [contentType: 'text/plain; charset=gb18030', file: 'charset-fixtures/ascii.bin'],
        'empty': [contentType: 'text/plain; charset=""', file: 'charset-fixtures/ascii.bin'],
        'malformed': [contentType: 'text/plain; charset', file: 'charset-fixtures/ascii.bin'],
        'malformed-bytes': [contentType: 'text/plain; charset=windows-1252', file: 'charset-fixtures/malformed-windows-1252.bin'],
    ]

    def charsetResponse = charsetResponses[responseCharsetCase]
    if (charsetResponse != null) {
        response
            .withHeader('Content-Type', charsetResponse.contentType)
            .withFile(charsetResponse.file)
    } else {
        response
            .withHeader('Content-Type', 'text/plain')
            .withContent('OK')
            .usingDefaultBehaviour()
    }
}

// For all other responses, use default behavior
else {
    respond()
        .withStatusCode(statusCode)
        .usingDefaultBehaviour()
}
