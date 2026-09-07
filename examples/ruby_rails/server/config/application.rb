require "bundler/setup"
require "rails"
require "action_controller/railtie"
require "rswag/api"
require "rswag/specs"
require "rack/deflater"

class CatalogApplication < Rails::Application
  config.load_defaults 8.0
  config.api_only = true
  config.eager_load = false
  config.secret_key_base = "local-example-secret-not-for-production-" * 3
  config.hosts.clear
  config.action_dispatch.show_exceptions = :none
  config.middleware.use Rack::Deflater
  config.logger = Logger.new($stdout)
end

class CatalogController < ActionController::API
  PRODUCT = {
    id: 42,
    name: "Tea & café",
    status: "available",
    customer: {
      id: "123e4567-e89b-12d3-a456-426614174000",
      name: "Ada Example"
    },
    tags: %w[tea 東京],
    attributes: {
      stock: 7
    },
    released: "2025-01-02",
    updated: "2025-01-02T03:04:05+02:00",
    note: nil
  }.freeze
  EMPTY = {
    text: "",
    count: 0,
    enabled: false,
    tags: [],
    fileName: "",
    contentType: "",
    bytes: [],
    raw: ""
  }.freeze

  def health
    render json: { ok: true }
  end

  def openapi
    render body: File.read(Rails.root.join("openapi/v1/openapi.json")),
           content_type: "application/json"
  end

  def product
    render json: PRODUCT
  end

  def echo_product
    render json: request.request_parameters
  end

  def details
    render json: PRODUCT.merge(source: "fixture")
  end

  def inspect_parameters
    render(
      json:
        EMPTY.merge(
          text: params[:key],
          count: Integer(params[:count]),
          enabled: params[:enabled] == "true",
          tags: params[:tags],
          contentType: request.headers["x-trace"],
          fileName: request.cookies["session"],
          raw: request.query_string
        )
    )
  end

  def form
    render(
      json:
        EMPTY.merge(
          text: params[:text],
          count: Integer(params[:count]),
          enabled: params[:enabled] == "true",
          tags: params[:tags],
          contentType: request.content_type,
          raw: request.raw_post
        )
    )
  end

  def upload
    file = params.require(:file)
    render(
      json:
        EMPTY.merge(
          text: params[:text],
          count: Integer(params[:count]),
          enabled: params[:enabled] == "true",
          fileName: file.original_filename,
          contentType: file.content_type,
          bytes: file.read.bytes
        )
    )
  end

  def binary
    send_data(
      [0, 1, 127, 128, 255].pack("C*"),
      type: "application/octet-stream",
      disposition: "inline"
    )
  end

  def echo_binary
    send_data(
      request.raw_post,
      type: "application/octet-stream",
      disposition: "inline"
    )
  end

  def text
    value, charset =
      {
        "utf8" => ["Grüße, 東京 👋", "UTF-8"],
        "latin1" => %w[café ISO-8859-1],
        "windows1252" => ["€ café", "Windows-1252"],
        "shift-jis" => %w[東京 Shift_JIS]
      }.fetch(params[:encoding])
    send_data(
      value.encode(charset),
      type: "text/plain; charset=#{charset}",
      disposition: "inline"
    )
  end

  def payment
    render json: {
             payment:
               (
                 if params[:kind] == "card"
                   { kind: "card", last4: "4242" }
                 else
                   { kind: "bank", iban: "DE02120300000000202051" }
                 end
               )
           }
  end

  def echo_payment
    value = params.require(:payment)
    valid =
      (value[:kind] == "card" && value[:last4] && !value[:iban]) ||
        (value[:kind] == "bank" && value[:iban] && !value[:last4])
    unless valid
      return(
        render json: {
                 detail: "Expected one card or bank payment"
               },
               status: 400
      )
    end
    render json: request.request_parameters
  end

  def contact
    value = params.require(:contact)
    unless value[:email] || value[:phone]
      return render json: { detail: "email or phone is required" }, status: 400
    end
    render json: request.request_parameters
  end

  def create_customer
    if params[:name].blank?
      return render json: { detail: "name is required" }, status: 400
    end
    render json: {
             id: PRODUCT[:customer][:id],
             name: params[:name]
           },
           status: 201
  end

  def delete_product
    head :no_content
  end

  def missing
    render json: { detail: "Product not found" }, status: 404
  end
end

Rails.application.initialize!
Rails.application.routes.draw do
  get "/health", to: "catalog#health"
  get "/openapi.json", to: "catalog#openapi"
  get "/products/42", to: "catalog#product"
  post "/products/echo", to: "catalog#echo_product"
  get "/products/42/details", to: "catalog#details"
  get "/inspect/:key", to: "catalog#inspect_parameters"
  post "/forms/echo", to: "catalog#form"
  post "/uploads", to: "catalog#upload"
  get "/files/sample", to: "catalog#binary"
  post "/files/echo", to: "catalog#echo_binary"
  get "/text/:encoding", to: "catalog#text"
  get "/payments/:kind", to: "catalog#payment"
  post "/payments/echo", to: "catalog#echo_payment"
  post "/contacts/echo", to: "catalog#contact"
  post "/customers", to: "catalog#create_customer"
  delete "/products/42", to: "catalog#delete_product"
  get "/missing", to: "catalog#missing"
end
