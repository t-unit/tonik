// Imposter response script for GitHub API integration tests.
//
// Handles two issues with the Imposter OpenAPI plugin:
// 1. Error status codes don't get Content-Type: application/json
// 2. Complex schemas produce invalid auto-generated data

def headers = context.request.headers
def responseStatus = headers['X-Response-Status'] ?: headers['x-response-status'] ?: '200'
def statusCode = Integer.parseInt(responseStatus)
def path = context.request.path

// ── Error responses ────────────────────────────────────────────────────
// GitHub uses a BasicError format: {"message": "...", "documentation_url": "..."}

if (statusCode >= 400) {
    def body = """{"message": "Mock error", "documentation_url": "https://docs.github.com/rest"}"""

    respond {
        withStatusCode statusCode
        withHeader 'Content-Type', 'application/json'
        withContent body
    }
    return
}

// ── Custom 200 responses for complex schemas ───────────────────────────
// Endpoints with complex nested schemas need hand-crafted JSON because
// Imposter's auto-generated examples are often invalid.

// GET /meta (root metadata)
if (path == '/meta') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent '{"verifiable_password_authentication": true}'
    }
    return
}

// Reusable rate-limit object
def rateLimitObj = '{"limit": 60, "remaining": 59, "reset": 1234567890, "used": 1}'

// GET /rate_limit
if (path == '/rate_limit') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"resources": {"core": ${rateLimitObj}, "search": ${rateLimitObj}}, "rate": ${rateLimitObj}}"""
    }
    return
}

// Reusable simple-user object
def simpleUser = '{"login": "octocat", "id": 1, "node_id": "MDQ6VXNlcjE=", "avatar_url": "https://example.com/avatar", "gravatar_id": "", "url": "", "html_url": "", "type": "User", "site_admin": false, "followers_url": "", "following_url": "", "gists_url": "", "starred_url": "", "subscriptions_url": "", "organizations_url": "", "repos_url": "", "events_url": "", "received_events_url": ""}'

// GET /users/{username}
if (path.matches('/users/[^/]+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"login": "octocat", "id": 1, "node_id": "MDQ6VXNlcjE=", "type": "User", "site_admin": false, "name": "The Octocat", "blog": "", "location": "San Francisco", "hireable": false, "public_repos": 8, "public_gists": 8, "followers": 1000, "following": 0, "created_at": "2011-01-25T18:44:36Z", "updated_at": "2024-01-01T00:00:00Z", "avatar_url": "https://example.com/avatar", "url": "https://api.github.com/users/octocat", "html_url": "https://github.com/octocat", "followers_url": "", "following_url": "", "gists_url": "", "starred_url": "", "subscriptions_url": "", "organizations_url": "", "repos_url": "", "events_url": "", "received_events_url": "", "gravatar_id": ""}"""
    }
    return
}

// Reusable repository URL templates
def repoUrls = '"archive_url": "", "assignees_url": "", "blobs_url": "", "branches_url": "", "collaborators_url": "", "comments_url": "", "commits_url": "", "compare_url": "", "contents_url": "", "contributors_url": "", "deployments_url": "", "downloads_url": "", "events_url": "", "forks_url": "", "git_commits_url": "", "git_refs_url": "", "git_tags_url": "", "git_url": "", "hooks_url": "", "issue_comment_url": "", "issue_events_url": "", "issues_url": "", "keys_url": "", "labels_url": "", "languages_url": "", "merges_url": "", "milestones_url": "", "notifications_url": "", "pulls_url": "", "releases_url": "", "ssh_url": "", "stargazers_url": "", "statuses_url": "", "subscribers_url": "", "subscription_url": "", "svn_url": "", "tags_url": "", "teams_url": "", "trees_url": "", "clone_url": "", "mirror_url": null'

// GET /repos/{owner}/{repo}
if (path.matches('/repos/[^/]+/[^/]+') && !path.matches('/repos/[^/]+/[^/]+/.+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"id": 1, "node_id": "MDEwOlJlcG9zaXRvcnkx", "name": "hello-world", "full_name": "octocat/hello-world", "private": false, "owner": ${simpleUser}, "html_url": "https://github.com/octocat/hello-world", "description": "A test repo", "fork": false, "url": "https://api.github.com/repos/octocat/hello-world", "created_at": "2011-01-26T19:01:12Z", "updated_at": "2024-01-01T00:00:00Z", "pushed_at": "2024-01-01T00:00:00Z", "homepage": "", "size": 1, "stargazers_count": 100, "watchers_count": 100, "language": "Dart", "has_issues": true, "has_projects": true, "has_wiki": true, "has_pages": false, "has_discussions": false, "forks_count": 10, "archived": false, "disabled": false, "open_issues_count": 5, "allow_forking": true, "is_template": false, "web_commit_signoff_required": false, "topics": [], "visibility": "public", "forks": 10, "open_issues": 5, "watchers": 100, "default_branch": "main", "network_count": 10, "subscribers_count": 50, "license": {"key": "mit", "name": "MIT License", "spdx_id": "MIT", "url": "https://api.github.com/licenses/mit", "node_id": "MDc6TGljZW5zZTEz"}, "hooks_url": "", "issue_comment_url": "", "issue_events_url": "", "issues_url": "", "keys_url": "", "labels_url": "", "languages_url": "", "merges_url": "", "milestones_url": "", "notifications_url": "", "pulls_url": "", "releases_url": "", "stargazers_url": "", "statuses_url": "", "subscribers_url": "", "subscription_url": "", ${repoUrls}}"""
    }
    return
}

// Reusable reaction-rollup object
def reactions = '{"url": "", "total_count": 0, "+1": 0, "-1": 0, "laugh": 0, "hooray": 0, "confused": 0, "heart": 0, "rocket": 0, "eyes": 0}'

// GET /repos/{owner}/{repo}/issues (list)
if (path.matches('/repos/[^/]+/[^/]+/issues') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """[{"id": 1, "node_id": "MDU6SXNzdWUx", "number": 1, "title": "Test issue", "state": "open", "locked": false, "body": "This is a test issue", "user": ${simpleUser}, "labels": [], "assignees": [], "comments": 0, "created_at": "2024-01-01T00:00:00Z", "updated_at": "2024-01-01T00:00:00Z", "url": "", "repository_url": "", "labels_url": "", "comments_url": "", "events_url": "", "html_url": "", "author_association": "OWNER", "reactions": ${reactions}, "timeline_url": ""}]"""
    }
    return
}

// GET /repos/{owner}/{repo}/issues/{issue_number}
if (path.matches('/repos/[^/]+/[^/]+/issues/[^/]+') && context.request.method == 'GET') {
    respond {
        withStatusCode 200
        withHeader 'Content-Type', 'application/json'
        withContent """{"id": 1, "node_id": "MDU6SXNzdWUx", "number": 1, "title": "Test issue", "state": "open", "locked": false, "body": "This is a test issue", "user": ${simpleUser}, "labels": [], "assignees": [], "comments": 0, "created_at": "2024-01-01T00:00:00Z", "updated_at": "2024-01-01T00:00:00Z", "closed_at": null, "url": "", "repository_url": "", "labels_url": "", "comments_url": "", "events_url": "", "html_url": "", "author_association": "OWNER", "reactions": ${reactions}, "timeline_url": ""}"""
    }
    return
}

// ── Default 200 responses ──────────────────────────────────────────────
// Let Imposter generate responses from the OpenAPI spec for simple schemas.

respond()
    .withStatusCode(statusCode)
    .usingDefaultBehaviour()
