// Imposter response script for OpenAI API integration tests.
//
// Handles two issues with the Imposter OpenAPI plugin:
// 1. Error status codes don't get Content-Type: application/json
// 2. Complex schemas produce invalid auto-generated data

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────
// OpenAI uses: {"error": {"message": "...", "type": "...", "code": "..."}}

if (statusCode >= 400) {
    def body = """{"error": {"message": "Mock error", "type": "invalid_request_error", "code": "mock_error"}}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses for complex schemas ───────────────────────────
// Note: Imposter prepends the server base path /v1 from the OpenAI spec.

// GET /v1/models
if (path == '/v1/models' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"object": "list", "data": [{"id": "gpt-4o", "object": "model", "created": 1700000000, "owned_by": "openai"}]}'
    }
    return
}

// GET /v1/models/{model}
if (path.matches('/v1/models/[^/]+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"id": "gpt-4o", "object": "model", "created": 1700000000, "owned_by": "openai"}'
    }
    return
}

// DELETE /v1/models/{model}
if (path.matches('/v1/models/[^/]+') && context.request.method == 'DELETE') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"id": "ft:gpt-4o:org:suffix:id", "object": "model", "deleted": true}'
    }
    return
}

// POST /v1/embeddings
if (path == '/v1/embeddings' && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"object": "list", "data": [{"object": "embedding", "embedding": [0.0023, -0.0091, 0.0152], "index": 0}], "model": "text-embedding-ada-002", "usage": {"prompt_tokens": 8, "total_tokens": 8}}'
    }
    return
}

// Reusable moderation category objects
def moderationCategories = '"sexual": false, "hate": false, "harassment": false, "self-harm": false, "sexual/minors": false, "hate/threatening": false, "violence/graphic": false, "self-harm/intent": false, "self-harm/instructions": false, "harassment/threatening": false, "violence": false, "illicit": false, "illicit/violent": false'
def moderationScores = '"sexual": 0.01, "hate": 0.01, "harassment": 0.01, "self-harm": 0.01, "sexual/minors": 0.01, "hate/threatening": 0.01, "violence/graphic": 0.01, "self-harm/intent": 0.01, "self-harm/instructions": 0.01, "harassment/threatening": 0.01, "violence": 0.01, "illicit": 0.01, "illicit/violent": 0.01'

def moderationInputTypes = '"sexual": ["text"], "hate": ["text"], "harassment": ["text"], "self-harm": ["text"], "sexual/minors": ["text"], "hate/threatening": ["text"], "violence/graphic": ["text"], "self-harm/intent": ["text"], "self-harm/instructions": ["text"], "harassment/threatening": ["text"], "violence": ["text"], "illicit": ["text"], "illicit/violent": ["text"]'

// POST /v1/moderations
if (path == '/v1/moderations' && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"id": "modr-abc123", "model": "text-moderation-007", "results": [{"flagged": false, "categories": {${moderationCategories}}, "category_scores": {${moderationScores}}, "category_applied_input_types": {${moderationInputTypes}}}]}"""
    }
    return
}

// POST /v1/chat/completions
if (path == '/v1/chat/completions' && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"id": "chatcmpl-abc123", "object": "chat.completion", "created": 1700000000, "model": "gpt-4o", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Hello!"}, "finish_reason": "stop"}], "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}}'
    }
    return
}

// GET /v1/files
if (path == '/v1/files' && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"object": "list", "data": [{"id": "file-abc123", "object": "file", "bytes": 120000, "created_at": 1700000000, "filename": "mydata.jsonl", "purpose": "fine-tune", "status": "processed"}], "first_id": "file-abc123", "last_id": "file-abc123", "has_more": false}'
    }
    return
}

// GET /v1/batches/{batch_id}
if (path.matches('/v1/batches/[^/]+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"id": "batch_abc123", "object": "batch", "endpoint": "/v1/chat/completions", "input_file_id": "file-abc123", "completion_window": "24h", "status": "completed", "created_at": 1700000000, "request_counts": {"total": 100, "completed": 95, "failed": 5}}'
    }
    return
}

// GET /v1/fine_tuning/jobs/{id}/events
if (path.matches('/v1/fine_tuning/jobs/[^/]+/events') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"object": "list", "data": [{"id": "fte-abc123", "object": "fine_tuning.job.event", "created_at": 1700000000, "level": "info", "message": "Training started"}], "has_more": false}'
    }
    return
}

// POST /v1/fine_tuning/jobs/{id}/cancel
if (path.matches('/v1/fine_tuning/jobs/[^/]+/cancel') && context.request.method == 'POST') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"id": "ftjob-abc123", "object": "fine_tuning.job", "model": "gpt-4o-mini-2024-07-18", "created_at": 1700000000, "finished_at": null, "fine_tuned_model": null, "organization_id": "org-abc123", "result_files": [], "status": "cancelled", "validation_file": null, "training_file": "file-abc123", "hyperparameters": {"n_epochs": "auto"}, "trained_tokens": null, "error": null, "seed": 12345, "estimated_finish": null, "integrations": []}'
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────
// Let Imposter generate responses from the OpenAPI spec for simple schemas.

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
