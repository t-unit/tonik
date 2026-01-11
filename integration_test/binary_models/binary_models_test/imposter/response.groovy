// Get the response status from the request header
def responseStatus = context.request.headers['X-Response-Status'] ?: '200'

// Set the response based on path and status
def response = respond().withStatusCode(Integer.parseInt(responseStatus))

if (context.request.path.matches('.*/files/[^/]+') && context.request.method == 'GET') {
    // getFile endpoint
    if (responseStatus == '200') {
        response.withHeader('Content-Type', 'application/octet-stream')
                .withFile('test_binary.bin')
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"File not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path.matches('.*/files/[^/]+') && context.request.method == 'POST') {
    // uploadFile endpoint
    if (responseStatus == '201') {
        def fileSize = context.request.body?.length() ?: 0
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"file-123","size":${fileSize},"message":"File uploaded successfully"}""")
    } else if (responseStatus == '400') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":400,"message":"Bad request"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path.matches('.*/images/[^/]+') && context.request.method == 'GET') {
    // getImage endpoint
    if (responseStatus == '200') {
        response.withHeader('Content-Type', 'image/png')
                .withFile('test.png')
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"Image not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/mixed/upload-info' && context.request.method == 'POST') {
    // uploadFileInfo endpoint
    if (responseStatus == '201') {
        // Parse JSON body to extract filename
        def fileName = 'unknown'
        try {
            def bodyStr = context.request.body
            def jsonSlurper = new groovy.json.JsonSlurper()
            def jsonBody = jsonSlurper.parseText(bodyStr)
            fileName = jsonBody?.fileName ?: 'unknown'
        } catch (Exception e) {
            // If parsing fails, use default
        }
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"file-456","size":1024,"message":"File info for '${fileName}' uploaded successfully"}""")
    } else if (responseStatus == '400') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":400,"message":"Bad request"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/mixed/file-with-metadata' && context.request.method == 'GET') {
    // getFileWithMetadata endpoint
    if (responseStatus == '200') {
        // Create thumbnail inline
        byte[] thumbnailBytes = new byte[1024]
        new Random().nextBytes(thumbnailBytes)
        def thumbnail = Base64.getEncoder().encodeToString(thumbnailBytes)
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"file-789","fileName":"example.pdf","size":2048,"thumbnail":"${thumbnail}","createdAt":"2023-12-20T10:30:00Z"}""")
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"File not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/base64/data' && context.request.method == 'POST') {
    // uploadBase64Data endpoint
    if (responseStatus == '201') {
        // Parse JSON body to extract name
        def dataName = 'unknown'
        try {
            def bodyStr = context.request.body
            def jsonSlurper = new groovy.json.JsonSlurper()
            def jsonBody = jsonSlurper.parseText(bodyStr)
            dataName = jsonBody?.name ?: 'unknown'
        } catch (Exception e) {
            // If parsing fails, use default
        }
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"data-999","message":"Base64 data '${dataName}' uploaded successfully"}""")
    } else if (responseStatus == '400') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":400,"message":"Bad request"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/content-encoded/data' && context.request.method == 'POST') {
    // uploadContentEncodedData endpoint (contentEncoding:base64)
    if (responseStatus == '201') {
        // Parse JSON body to extract name
        def dataName = 'unknown'
        try {
            def bodyStr = context.request.body
            def jsonSlurper = new groovy.json.JsonSlurper()
            def jsonBody = jsonSlurper.parseText(bodyStr)
            dataName = jsonBody?.name ?: 'unknown'
        } catch (Exception e) {
            // If parsing fails, use default
        }
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"data-999","message":"ContentEncoded data '${dataName}' uploaded successfully"}""")
    } else if (responseStatus == '400') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":400,"message":"Bad request"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/content-encoded/data' && context.request.method == 'GET') {
    // getContentEncodedData endpoint (contentEncoding:base64)
    if (responseStatus == '200') {
        // Create base64 encoded data
        byte[] sampleData = new byte[512]
        new Random().nextBytes(sampleData)
        def base64Encoded = Base64.getEncoder().encodeToString(sampleData)
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"name":"test-data","encodedData":"${base64Encoded}","description":"Sample contentEncoding base64 data"}""")
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"Data not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/base64/data' && context.request.method == 'GET') {
    // getBase64Data endpoint
    if (responseStatus == '200') {
        // Create base64 encoded data
        byte[] sampleData = new byte[512]
        new Random().nextBytes(sampleData)
        def base64Encoded = Base64.getEncoder().encodeToString(sampleData)
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"name":"test-data","encodedData":"${base64Encoded}","description":"Sample base64 encoded data"}""")
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"Data not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/oas31/raw-binary' && context.request.method == 'GET') {
    // getRawBinary endpoint (OAS 3.1 empty schema)
    if (responseStatus == '200') {
        response.withHeader('Content-Type', 'application/octet-stream')
                .withFile('test_binary.bin')
    } else if (responseStatus == '404') {
        response.withHeader('Content-Type', 'application/json')
                .withContent('{"code":404,"message":"Binary data not found"}')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/oas31/raw-binary' && context.request.method == 'POST') {
    // uploadRawBinary endpoint (OAS 3.1 empty schema)
    if (responseStatus == '201') {
        def fileSize = context.request.body?.length() ?: 0
        response.withHeader('Content-Type', 'application/json')
                .withContent("""{"id":"oas31-binary-${System.currentTimeMillis()}","size":${fileSize},"message":"OAS 3.1 binary uploaded"}""")
    } else {
        response.usingDefaultBehaviour()
    }
    
} else if (context.request.path == '/api/v1/oas31/image' && context.request.method == 'GET') {
    // getImageOas31 endpoint (OAS 3.1 empty schema)
    if (responseStatus == '200') {
        response.withHeader('Content-Type', 'image/png')
                .withFile('test.png')
    } else {
        response.usingDefaultBehaviour()
    }
    
} else {
    // Use default OpenAPI behavior for unhandled paths
    response.usingDefaultBehaviour()
}
