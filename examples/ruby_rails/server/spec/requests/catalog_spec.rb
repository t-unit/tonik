require_relative "../swagger_helper"
require "tempfile"

RSpec.describe "Catalog", type: :request do
  path "/products/42" do
    get "Deterministic product" do
      tags "Catalog"
      operationId "jsonProduct"
      produces "application/json"
      response "200", "product" do
        schema "$ref" => "#/components/schemas/Product"
        run_test! do |response|
          expect(JSON.parse(response.body)["name"]).to eq("Tea & café")
        end
      end
    end
    delete "Delete product" do
      tags "Catalog"
      operationId "deleteProduct"
      response "204", "deleted" do
        run_test! { |response| expect(response.body).to eq("") }
      end
    end
  end
  path "/products/echo" do
    post "Echo product" do
      tags "Catalog"
      operationId "echoProduct"
      consumes "application/json"
      produces "application/json"
      parameter name: :body,
                in: :body,
                schema: {
                  "$ref" => "#/components/schemas/Product"
                }
      response "200", "product" do
        schema "$ref" => "#/components/schemas/Product"
        let(:body) { CatalogController::PRODUCT }
        run_test!
      end
    end
  end
  path "/products/42/details" do
    get "Composed flat product" do
      tags "Catalog"
      operationId "details"
      produces "application/json"
      response "200", "details" do
        schema "$ref" => "#/components/schemas/Details"
        run_test! do |response|
          expect(JSON.parse(response.body)["source"]).to eq("fixture")
        end
      end
    end
  end
  path "/inspect/{key}" do
    get "Inspect parsed parameters" do
      tags "Catalog"
      operationId "inspect"
      produces "application/json"
      parameter name: :key, in: :path, required: true, schema: { type: :string }
      parameter name: :count,
                in: :query,
                required: true,
                schema: {
                  type: :integer
                }
      parameter name: :enabled,
                in: :query,
                required: true,
                schema: {
                  type: :boolean
                }
      parameter name: "tags[]",
                in: :query,
                required: true,
                style: :form,
                explode: true,
                schema: {
                  type: :array,
                  items: {
                    type: :string
                  }
                }
      parameter name: "x-trace",
                in: :header,
                required: true,
                schema: {
                  type: :string
                }
      parameter name: :session,
                in: :cookie,
                required: true,
                schema: {
                  type: :string
                }
      response "200", "receipt" do
        schema "$ref" => "#/components/schemas/Receipt"
        let(:key) { "tea" }
        let(:count) { 2 }
        let(:enabled) { false }
        let(:"tags[]") { ["a,b", "東京 space"] }
        let(:"x-trace") { "trace-42" }
        let(:session) { "session-42" }
        before { cookies[:session] = "session-42" }
        run_test! do |response|
          expect(JSON.parse(response.body)["tags"]).to eq(["a,b", "東京 space"])
        end
      end
    end
  end
  path "/forms/echo" do
    post "URL encoded form" do
      tags "Catalog"
      operationId "form"
      consumes "application/x-www-form-urlencoded"
      produces "application/json"
      # The formatter needs the full OAS3 body schema; RequestFactory still uses
      # individual formData fields when submitting a real form request.
      parameter name: :body,
                in: :body,
                required: true,
                schema: {
                  "$ref" => "#/components/schemas/FormFields"
                }
      parameter name: :text,
                in: :formData,
                required: true,
                schema: {
                  type: :string
                }
      parameter name: :count,
                in: :formData,
                required: true,
                schema: {
                  type: :integer
                }
      parameter name: :enabled,
                in: :formData,
                required: true,
                schema: {
                  type: :boolean
                }
      parameter name: "tags[]",
                in: :formData,
                required: true,
                schema: {
                  type: :array,
                  items: {
                    type: :string
                  }
                }
      response "200", "receipt" do
        schema "$ref" => "#/components/schemas/Receipt"
        let(:text) { "café + tea & milk=x" }
        let(:count) { 2 }
        let(:enabled) { false }
        # Rack::Test adds [] to Ruby arrays; this is one explicit bracketed wire field.
        # The Dart tests exercise multiple values using the emitted array schema.
        let(:"tags[]") { "tea" }
        run_test! do |response|
          expect(JSON.parse(response.body)["text"]).to eq("café + tea & milk=x")
        end
      end
    end
  end
  path "/uploads" do
    post "Multipart upload" do
      tags "Catalog"
      operationId "upload"
      consumes "multipart/form-data"
      produces "application/json"
      parameter name: :body,
                in: :body,
                required: true,
                schema: {
                  "$ref" => "#/components/schemas/UploadFields"
                }
      parameter name: :file,
                in: :formData,
                required: true,
                schema: {
                  type: :string,
                  format: :binary
                }
      parameter name: :text,
                in: :formData,
                required: true,
                schema: {
                  type: :string
                }
      parameter name: :count,
                in: :formData,
                required: true,
                schema: {
                  type: :integer
                }
      parameter name: :enabled,
                in: :formData,
                required: true,
                schema: {
                  type: :boolean
                }
      response "200", "receipt" do
        schema "$ref" => "#/components/schemas/Receipt"
        let(:file) do
          temp = Tempfile.new("sample.bin")
          temp.binmode
          temp.write([0, 1, 127, 128, 255].pack("C*"))
          temp.rewind
          Rack::Test::UploadedFile.new(
            temp.path,
            "application/octet-stream",
            true,
            original_filename: "sample.bin"
          )
        end
        let(:text) { "café + tea & milk" }
        let(:count) { 2 }
        let(:enabled) { false }
        run_test! do |response|
          expect(JSON.parse(response.body)["bytes"]).to eq(
            [0, 1, 127, 128, 255]
          )
        end
      end
    end
  end
  path "/files/sample" do
    get "Binary download" do
      tags "Catalog"
      operationId "binary"
      produces "application/octet-stream"
      response "200", "binary" do
        schema type: :string, format: :binary
        before { |example| submit_request(example.metadata) }
        it "returns exact binary bytes" do
          expect(response.status).to eq(200)
          expect(response.media_type).to eq("application/octet-stream")
          expect(response.body.bytes).to eq([0, 1, 127, 128, 255])
        end
      end
    end
  end
  path "/files/echo" do
    post "Binary upload" do
      tags "Catalog"
      operationId "echoBinary"
      consumes "application/octet-stream"
      produces "application/octet-stream"
      parameter name: :body,
                in: :body,
                schema: {
                  type: :string,
                  format: :binary
                }
      response "200", "binary" do
        schema type: :string, format: :binary
        let(:body) { [0, 1, 127, 128, 255].pack("C*") }
        before { |example| submit_request(example.metadata) }
        it "returns the uploaded bytes" do
          expect(response.status).to eq(200)
          expect(response.body.bytes).to eq([0, 1, 127, 128, 255])
        end
      end
    end
  end
  path "/text/{encoding}" do
    get "Encoded text" do
      tags "Catalog"
      operationId "text"
      produces "text/plain"
      parameter name: :encoding,
                in: :path,
                required: true,
                schema: {
                  type: :string
                }
      response "200", "text" do
        schema type: :string
        let(:encoding) { "latin1" }
        before { |example| submit_request(example.metadata) }
        it "encodes actual Latin-1 bytes" do
          expect(response.status).to eq(200)
          expect(response.body.bytes).to eq([99, 97, 102, 233])
          expect(response.headers["content-type"].downcase).to include(
            "iso-8859-1"
          )
        end
      end
    end
  end
  path "/payments/{kind}" do
    get "Discriminated payment" do
      tags "Catalog"
      operationId "payment"
      produces "application/json"
      parameter name: :kind,
                in: :path,
                required: true,
                schema: {
                  type: :string
                }
      response "200", "payment" do
        schema "$ref" => "#/components/schemas/PaymentDocument"
        let(:kind) { "card" }
        run_test!
      end
    end
  end
  path "/payments/echo" do
    post "Echo payment" do
      tags "Catalog"
      operationId "echoPayment"
      consumes "application/json"
      produces "application/json"
      parameter name: :body,
                in: :body,
                schema: {
                  "$ref" => "#/components/schemas/PaymentDocument"
                }
      response "200", "payment" do
        schema "$ref" => "#/components/schemas/PaymentDocument"
        let(:body) do
          { payment: { kind: "bank", iban: "DE02120300000000202051" } }
        end
        run_test!
      end
    end
  end
  path "/contacts/echo" do
    post "Overlapping contact" do
      tags "Catalog"
      operationId "contact"
      consumes "application/json"
      produces "application/json"
      parameter name: :body,
                in: :body,
                schema: {
                  "$ref" => "#/components/schemas/ContactDocument"
                }
      response "200", "contact" do
        schema "$ref" => "#/components/schemas/ContactDocument"
        let(:body) do
          { contact: { email: "ada@example.com", phone: "+49 123" } }
        end
        run_test! do |response|
          expect(JSON.parse(response.body)["contact"]).to eq(
            "email" => "ada@example.com",
            "phone" => "+49 123"
          )
        end
      end
    end
  end
  path "/customers" do
    post "Create customer" do
      tags "Catalog"
      operationId "createCustomer"
      consumes "application/json"
      produces "application/json"
      parameter name: :body,
                in: :body,
                schema: {
                  "$ref" => "#/components/schemas/CustomerInput"
                }
      response "201", "customer" do
        schema "$ref" => "#/components/schemas/Customer"
        let(:body) { { name: "Ada Example", secret: "fake-secret" } }
        run_test! do |response|
          expect(JSON.parse(response.body)).not_to have_key("secret")
        end
      end
    end
  end
  path "/missing" do
    get "Declared error" do
      tags "Catalog"
      operationId "missing"
      produces "application/json"
      response "404", "missing" do
        schema "$ref" => "#/components/schemas/ApiError"
        run_test!
      end
    end
  end
end
