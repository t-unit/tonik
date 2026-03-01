// Imposter response script for multipart tests.
// Handles both OAS 3.0 and OAS 3.1 endpoints.
//
// Note: For multipart/form-data requests, context.request.body is empty.
// Use context.request.formParams to access parsed text fields.
// Binary file parts do NOT appear in formParams.
def path = context.request.path
def formParams = context.request.formParams ?: [:]

switch (path) {

    // OAS 3.0 endpoints:

    case '/multipart/simple':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Name', formParams.containsKey('name').toString()
            withHeader 'X-Has-Age', formParams.containsKey('age').toString()
            withHeader 'X-Has-Active', formParams.containsKey('active').toString()
            withHeader 'X-Param-Name', (formParams['name'] ?: '')
            withHeader 'X-Param-Age', (formParams['age'] ?: '')
            withHeader 'X-Param-Active', (formParams['active'] ?: '')
            withContent '{"name":"John Doe","age":30,"active":true}'
        }
        break

    case '/multipart/binary':
        // Binary file parts do not appear in formParams.
        // Text fields like 'description' do.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Description', formParams.containsKey('description').toString()
            withHeader 'X-Param-Description', (formParams['description'] ?: '')
            withContent '{"filename":"file","size":3}'
        }
        break

    case '/multipart/enum':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Status', formParams.containsKey('status').toString()
            withHeader 'X-Param-Status', (formParams['status'] ?: '')
            withContent '{"status":"active"}'
        }
        break

    case '/multipart/complex':
        // The profile field should be JSON-encoded as a string value.
        def profileValue = formParams['profile'] ?: ''
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Label', formParams.containsKey('label').toString()
            withHeader 'X-Has-Profile', formParams.containsKey('profile').toString()
            withHeader 'X-Param-Label', (formParams['label'] ?: '')
            withHeader 'X-Profile-Contains-FirstName', profileValue.contains('firstName').toString()
            withHeader 'X-Profile-Contains-LastName', profileValue.contains('lastName').toString()
            withContent '{"label":"test","profileJson":"{}"}'
        }
        break

    case '/multipart/arrays':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Tags', formParams.containsKey('tags').toString()
            withHeader 'X-Has-Priorities', formParams.containsKey('priorities').toString()
            withContent '{"tagCount":3,"priorityCount":2}'
        }
        break

    case '/multipart/mixed-required':
        def hasRequired = formParams.containsKey('requiredField').toString()
        def hasOptional = formParams.containsKey('optionalField').toString()
        def hasOptionalFile = formParams.containsKey('optionalFile').toString()
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Required', hasRequired
            withHeader 'X-Has-Optional', hasOptional
            withHeader 'X-Has-OptionalFile', hasOptionalFile
            withHeader 'X-Param-Required', (formParams['requiredField'] ?: '')
            withContent "{\"success\":true,\"message\":\"required=${hasRequired},optional=${hasOptional},optionalFile=${hasOptionalFile}\"}"
        }
        break

    case '/multipart/encoding-override':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Data', formParams.containsKey('data').toString()
            withHeader 'X-Has-Label', formParams.containsKey('label').toString()
            withHeader 'X-Param-Data', (formParams['data'] ?: '')
            withHeader 'X-Param-Label', (formParams['label'] ?: '')
            withContent '{"success":true,"message":"ok"}'
        }
        break

    case '/multipart/multiple-files':
        // Binary file parts don't appear in formParams.
        // We can only verify the server received the request.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withContent '{"fileCount":3}'
        }
        break

    case '/multipart/response':
        // Return a multipart/form-data response to trigger ResponseDecodingException.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'multipart/form-data; boundary=testboundary'
            withContent '--testboundary\r\nContent-Disposition: form-data; name="name"\r\n\r\nJohn\r\n--testboundary--'
        }
        break

    case '/multipart/headers':
        // Per-part headers turn fields into "file" parts in Dio,
        // so text fields with headers may not appear in formParams.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Description', formParams.containsKey('description').toString()
            withContent '{"success":true,"message":"headers found"}'
        }
        break

    case '/custom/multipart':
        def requestContentType = context.request.headers['Content-Type'] ?: 'unknown'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Received-Content-Type', requestContentType
            withHeader 'X-Has-Field1', formParams.containsKey('field1').toString()
            withHeader 'X-Has-Field2', formParams.containsKey('field2').toString()
            withHeader 'X-Param-Field1', (formParams['field1'] ?: '')
            withHeader 'X-Param-Field2', (formParams['field2'] ?: '')
            withContent '{"success":true,"message":"custom multipart received"}'
        }
        break

    // OAS 3.1 endpoints:

    case '/multipart31/pipe-delimited':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Items', formParams.containsKey('items').toString()
            withHeader 'X-Param-Items', (formParams['items'] ?: '')
            withContent '{"success":true,"message":"pipe-delimited received"}'
        }
        break

    case '/multipart31/default-explode':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Values', formParams.containsKey('values').toString()
            withHeader 'X-Param-Values', (formParams['values'] ?: '')
            withContent '{"success":true,"message":"default-explode received"}'
        }
        break

    case '/multipart31/basic':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Name', formParams.containsKey('name').toString()
            withHeader 'X-Param-Name', (formParams['name'] ?: '')
            withContent '{"success":true,"message":"basic 3.1 received"}'
        }
        break

    default:
        respond().usingDefaultBehaviour()
        break
}
