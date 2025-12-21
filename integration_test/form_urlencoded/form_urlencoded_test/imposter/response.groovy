// Imposter response script for form-urlencoded tests
def path = context.request.path

switch (path) {
    case '/form/simple':
        def formBody = 'name=John+Doe&age=30'
        def requestBody = context.request.body
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withHeader 'x-raw-request-body', requestBody
            withContent formBody
        }
        break
        
    case '/form/special-chars':
        def formBody = 'text=a%26b%3Dc%2Bd&url=50%25+off%21+Buy+now+%26+save+%24%24%24'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/arrays':
        def formBody = 'colors=red&colors=green&colors=blue&numbers=1&numbers=2&numbers=3'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/types':
        def parts = [
            "stringValue=hello",
            "intValue=42",
            "doubleValue=3.14",
            "boolValue=true",
            "dateValue=2023-12-25T10%3A30%3A00Z"
        ]
        def formBody = parts.join('&')
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/response':
        def formBody = 'name=John+Doe&age=30'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/empty-null':
        def formBody = 'emptyString=&nullableString=not+empty'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/nested':
        def formBody = 'topLevel=value&nested%5BinnerProp%5D=nested+value'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/multi-content-request':
        def formBody = 'name=John+Doe&age=30'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/multi-content-response':
        def formBody = 'name=John+Doe&age=30'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/form/multi-content-both':
        def parts = [
            "stringValue=hello",
            "intValue=42",
            "doubleValue=3.14",
            "boolValue=true",
            "dateValue=2023-12-25T10%3A30%3A00Z"
        ]
        def formBody = parts.join('&')
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/x-www-form-urlencoded'
            withContent formBody
        }
        break
        
    case '/custom/form':
        def formBody = 'field1=custom+value&field2=100'
        respond {
            withStatusCode 200
            withHeader 'Content-Type', 'application/vnd.custom-form'
            withContent formBody
        }
        break
        
    default:
        // Let Imposter handle all other endpoints with standard OpenAPI behavior
        break
}
