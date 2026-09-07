# Rails API + rswag

From the repository root ([setup](../README.md#run)):

```sh
./examples/run.sh ruby_rails
```

The [Rails app](server/config/application.rb) runs without a database. Rails
8.0.2.1, rswag 2.16.0 and Ruby 3.4.5 are pinned in the [Gemfile](server/Gemfile),
lockfile and Dockerfile.

rswag generates OpenAPI 3.0 from [request specs](server/spec/requests/catalog_spec.rb).
The image build executes those specs with dry-run disabled, then Puma serves
the generated document and receives the Dart requests.

- rswag's formatter needs a full body schema, while its request builder needs
  individual `formData` fields. The form/upload specs declare both.
- Rack arrays use bracketed field names such as `tags[]`. The request specs set
  the Rails cookie jar explicitly because rswag does not populate it from an
  `in: cookie` parameter.
- Binary/text specs assert bytes directly because rswag's usual response matcher
  expects JSON. Payment/contact handlers enforce the declared composition shapes.

See the [Dart demo](client/bin/example.dart), [live tests](client/test/live_test.dart),
and [rswag documentation](https://github.com/rswag/rswag).
