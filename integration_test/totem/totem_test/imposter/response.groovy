// Imposter response script for Totem Mobile API integration tests.

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)

// ── Error responses ────────────────────────────────────────────────────

if (statusCode >= 400) {
    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent """{"error": "Mock error", "status": ${statusCode}}"""
    }
    return
}

// ── DELETE returns boolean ─────────────────────────────────────────────

if (context.request.method == 'DELETE') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent 'true'
    }
    return
}

// Imposter's spec-generated examples emit invalid `{}` for
// anyOf-nullable properties, so these endpoints serve static bodies.

def path = context.request.path

if (path == '/api/mobile/protected/users/current') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '''{
            "profile_avatar_type": "TD",
            "circle_count": 42,
            "name": "Test User",
            "slug": null,
            "is_staff": false,
            "api_key": "d864e295-213e-4bf0-b27a-81e6d5583cdf",
            "profile_avatar_seed": "0bff137a-4255-460f-a3da-bc6b0d9c2a34",
            "profile_image": null,
            "email": "user@example.com",
            "date_created": "2026-07-14T18:11:14Z"
        }'''
    }
    return
}

if (path.startsWith('/api/mobile/protected/users/profile/')) {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '''{
            "profile_avatar_type": "TD",
            "circle_count": null,
            "name": null,
            "slug": "test-user",
            "is_staff": false,
            "profile_avatar_seed": "0bff137a-4255-460f-a3da-bc6b0d9c2a34",
            "profile_image": null,
            "date_created": "2026-07-14T18:11:14Z"
        }'''
    }
    return
}

// ── Default: let Imposter generate responses from the spec ─────────────

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
