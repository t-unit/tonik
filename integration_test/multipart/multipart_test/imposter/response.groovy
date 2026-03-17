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
        // Per RFC 7578 §4.3 and OAS 3.x default, each array element is sent
        // as a separate form field with the same name (repeated fields).
        // formParams['tags'] will contain the last value; the test verifies
        // the full set of fields client-side via FormData.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Tags', formParams.containsKey('tags').toString()
            withHeader 'X-Has-Priorities', formParams.containsKey('priorities').toString()
            withHeader 'X-Param-Tags', (formParams['tags'] ?: '')
            withHeader 'X-Param-Priorities', (formParams['priorities'] ?: '')
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

    case '/multipart/byte':
        // format:byte fields default to application/octet-stream in OAS 3.0.
        // Binary parts do NOT appear in formParams (unlike text/plain parts).
        // If the byte field appeared in formParams it would indicate the wrong
        // content type (text/plain) was used — the old StringModel behavior.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Label', formParams.containsKey('label').toString()
            withHeader 'X-Param-Label', (formParams['label'] ?: '')
            withHeader 'X-Has-Data', formParams.containsKey('data').toString()
            withContent '{"success":true,"message":"byte received"}'
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

    case '/multipart31/deep-object':
        // deepObject sends separate form fields with bracket-notation names:
        //   name="address[city]" value="Berlin"
        //   name="address[zip]"  value="10115"
        def addrCity = formParams['address[city]'] ?: ''
        def addrZip = formParams['address[zip]'] ?: ''
        def hasAddress = (formParams.containsKey('address[city]') || formParams.containsKey('address[zip]')).toString()
        def addressValue = "address[city]=${addrCity}&address[zip]=${addrZip}"
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Address', hasAddress
            withHeader 'X-Address-Has-City', formParams.containsKey('address[city]').toString()
            withHeader 'X-Address-Has-Zip', formParams.containsKey('address[zip]').toString()
            withHeader 'X-Address-Value', addressValue
            withContent '{"success":true,"message":"deep-object received"}'
        }
        break

    case '/multipart31/deep-object-types':
        // deepObject sends separate form fields with bracket-notation names:
        //   name="profile[name]" value="Alice"
        //   name="profile[age]"  value="30"
        //   name="profile[active]" value="true"
        def profName = formParams['profile[name]'] ?: ''
        def profAge = formParams['profile[age]'] ?: ''
        def profActive = formParams['profile[active]'] ?: ''
        def hasProfile = (formParams.containsKey('profile[name]') || formParams.containsKey('profile[age]') || formParams.containsKey('profile[active]')).toString()
        def profileValue = "profile[name]=${profName}&profile[age]=${profAge}&profile[active]=${profActive}"
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Profile', hasProfile
            withHeader 'X-Profile-Has-Name', formParams.containsKey('profile[name]').toString()
            withHeader 'X-Profile-Has-Age', formParams.containsKey('profile[age]').toString()
            withHeader 'X-Profile-Has-Active', formParams.containsKey('profile[active]').toString()
            withHeader 'X-Profile-Value', profileValue
            withContent '{"success":true,"message":"deep-object-types received"}'
        }
        break

    case '/multipart31/deep-object-optional':
        // deepObject sends separate form fields with bracket-notation names.
        // shipping is required, billing is optional.
        def shipCity = formParams['shipping[city]'] ?: ''
        def shipZip = formParams['shipping[zip]'] ?: ''
        def hasShipping = (formParams.containsKey('shipping[city]') || formParams.containsKey('shipping[zip]')).toString()
        def hasBilling = (formParams.containsKey('billing[city]') || formParams.containsKey('billing[zip]')).toString()
        def shippingValue = "shipping[city]=${shipCity}&shipping[zip]=${shipZip}"
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Shipping', hasShipping
            withHeader 'X-Has-Billing', hasBilling
            withHeader 'X-Shipping-Value', shippingValue
            withContent '{"success":true,"message":"deep-object-optional received"}'
        }
        break

    case '/multipart31/url-encoded-object':
        // The address field is serialized as URL-encoded key-value pairs.
        // formParams sees the raw part content: firstName=John&lastName=Doe
        def addressValue = formParams['address'] ?: ''
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Address', formParams.containsKey('address').toString()
            withHeader 'X-Address-Has-First-Name', addressValue.contains('firstName=').toString()
            withHeader 'X-Address-Has-Last-Name', addressValue.contains('lastName=').toString()
            withHeader 'X-Address-Value', addressValue
            withContent '{"success":true,"message":"url-encoded-object received"}'
        }
        break

    case '/multipart31/style-primitives':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Name', formParams.containsKey('name').toString()
            withHeader 'X-Has-Count', formParams.containsKey('count').toString()
            withHeader 'X-Has-Active', formParams.containsKey('active').toString()
            withHeader 'X-Param-Name', (formParams['name'] ?: '')
            withHeader 'X-Param-Count', (formParams['count'] ?: '')
            withHeader 'X-Param-Active', (formParams['active'] ?: '')
            withContent '{"success":true,"message":"style-primitives received"}'
        }
        break

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
        // Repeated fields: formParams['values'] returns the last value.
        // The test verifies the full set of fields client-side via FormData.
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Values', formParams.containsKey('values').toString()
            withHeader 'X-Param-Values', (formParams['values'] ?: '')
            withContent '{"success":true,"message":"default-explode received"}'
        }
        break

    case '/multipart31/any-model':
        // The data field should be JSON-encoded (not toString()).
        // Passing a Map like {firstName: John} must produce {"firstName":"John"},
        // not the Dart literal {firstName: John}.
        def dataValue = formParams['data'] ?: ''
        def isValidJson = dataValue.startsWith('{') || dataValue.startsWith('[') ||
                          dataValue ==~ /^-?\d+(\.\d+)?$/ || dataValue ==~ /^".*"$/ ||
                          dataValue == 'true' || dataValue == 'false' || dataValue == 'null'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Data', formParams.containsKey('data').toString()
            withHeader 'X-Data-Value', dataValue
            withHeader 'X-Data-Is-Valid-Json', isValidJson.toString()
            withHeader 'X-Data-Contains-FirstName', dataValue.contains('"firstName"').toString()
            withContent '{"success":true,"message":"any-model received"}'
        }
        break

    case '/multipart31/byte':
        // format:byte fields default to application/octet-stream in OAS 3.1.
        // Binary parts do NOT appear in formParams (unlike text/plain parts).
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Label', formParams.containsKey('label').toString()
            withHeader 'X-Param-Label', (formParams['label'] ?: '')
            withHeader 'X-Has-Data', formParams.containsKey('data').toString()
            withContent '{"success":true,"message":"byte 3.1 received"}'
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

    case '/multipart/anyof-model':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Model', formParams.containsKey('model').toString()
            withHeader 'X-Param-Model', (formParams['model'] ?: '')
            withContent '{"success":true,"message":"anyof-model received"}'
        }
        break

    case '/multipart/kitchen-sink':
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/json'
            withHeader 'X-Has-Name', formParams.containsKey('name').toString()
            withHeader 'X-Has-Temperature', formParams.containsKey('temperature').toString()
            withHeader 'X-Has-Active', formParams.containsKey('active').toString()
            withHeader 'X-Has-Status', formParams.containsKey('status').toString()
            withHeader 'X-Has-Tags', formParams.containsKey('tags').toString()
            withHeader 'X-Has-Metadata', formParams.containsKey('metadata').toString()
            withHeader 'X-Param-Name', (formParams['name'] ?: '')
            withHeader 'X-Param-Temperature', (formParams['temperature'] ?: '')
            withHeader 'X-Param-Active', (formParams['active'] ?: '')
            withHeader 'X-Param-Status', (formParams['status'] ?: '')
            withContent '{"success":true,"message":"kitchen-sink received"}'
        }
        break

    case '/multipart/multi-response':
        // Check the request to decide which response type to send.
        // Use a custom header to signal the desired response format.
        def wantBinary = context.request.headers['X-Want-Binary'] == 'true'
        if (wantBinary) {
            respond {
                withStatusCode 200
                withHeader 'Content-Type', 'application/octet-stream'
                withContent 'BINARY_DATA_HERE'
            }
        } else {
            respond {
                withStatusCode 200
                withHeader 'Content-Type', 'application/json'
                withContent '{"success":true,"message":"multi-response json"}'
            }
        }
        break

    default:
        respond().usingDefaultBehaviour()
        break
}
