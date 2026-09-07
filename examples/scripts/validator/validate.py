"""Validate the producer document and the contract the live Dart examples use."""
import json
import sys
from openapi_spec_validator import validate

with open(sys.argv[1]) as source:
    schema = json.load(source)
assert schema["openapi"].startswith(("3.0.", "3.1.")), schema["openapi"]
validate(schema)


def resolve(value):
    while "$ref" in value:
        reference = value["$ref"]
        assert reference.startswith("#/"), f"Expected a self-contained document: {reference}"
        value = schema
        for part in reference[2:].split("/"):
            value = value[part.replace("~1", "/").replace("~0", "~")]
    return value


def contains_keyword(value, keyword, visited=None):
    visited = set() if visited is None else visited
    if isinstance(value, list):
        return any(contains_keyword(item, keyword, visited) for item in value)
    if not isinstance(value, dict):
        return False
    if keyword in value:
        return True
    if "$ref" in value:
        if value["$ref"] in visited:
            return False
        visited.add(value["$ref"])
        return contains_keyword(resolve(value), keyword, visited)
    return any(contains_keyword(item, keyword, visited) for item in value.values())


for path in ["/products/42", "/products/echo", "/inspect/{key}", "/forms/echo", "/uploads", "/files/sample", "/files/echo", "/text/{encoding}", "/payments/{kind}", "/payments/echo", "/customers", "/missing"]:
    assert path in schema["paths"], f"Missing required route: {path}"

upload = resolve(schema["paths"]["/uploads"]["post"]["requestBody"])
upload = resolve(upload["content"]["multipart/form-data"]["schema"])
assert upload["type"] == "object", "Multipart must document an object with file and scalar fields"
assert {"file", "text", "count", "enabled"}.issubset(upload["properties"])
assert resolve(upload["properties"]["file"])["format"] == "binary"
assert resolve(upload["properties"]["count"])["type"] == "integer"
assert resolve(upload["properties"]["enabled"])["type"] == "boolean"

form = resolve(schema["paths"]["/forms/echo"]["post"]["requestBody"])
form = resolve(form["content"]["application/x-www-form-urlencoded"]["schema"])
assert form["type"] == "object", "A form must document all fields as an object"
assert {"text", "count", "enabled"}.issubset(form["properties"])
assert "tags" in form["properties"] or "tags[]" in form["properties"]

binary = resolve(schema["paths"]["/files/sample"]["get"]["responses"]["200"])
assert "application/octet-stream" in binary["content"]
payment = resolve(schema["paths"]["/payments/{kind}"]["get"]["responses"]["200"])
assert contains_keyword(payment["content"]["application/json"]["schema"], "oneOf"), "Expected a reachable payment union"
if "/contacts/echo" in schema["paths"]:
    contact = resolve(schema["paths"]["/contacts/echo"]["post"]["requestBody"])
    assert contains_keyword(contact["content"]["application/json"]["schema"], "anyOf")
if "/products/42/details" in schema["paths"]:
    details = resolve(schema["paths"]["/products/42/details"]["get"]["responses"]["200"])
    assert contains_keyword(details["content"]["application/json"]["schema"], "allOf")
if "/uploads/json" in schema["paths"]:
    metadata = resolve(schema["paths"]["/uploads/json"]["post"]["requestBody"])["content"]["multipart/form-data"]
    assert metadata["encoding"]["metadata"]["contentType"] == "application/json"

print(f"Validated OpenAPI {schema['openapi']} and live-example contract")
