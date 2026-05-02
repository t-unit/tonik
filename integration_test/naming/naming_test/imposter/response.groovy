def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'

respond()
    .withStatusCode(Integer.parseInt(responseStatus))
    .usingDefaultBehaviour()