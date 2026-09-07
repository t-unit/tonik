# rswag's supported schema DSL is the source for this spec-driven producer.
SCHEMAS = {
  Customer: { type: :object, required: %w[id name], properties: { id: { type: :string, format: :uuid }, name: { type: :string } } },
  Product: { type: :object, required: %w[id name status customer tags attributes released updated], properties: {
    id: { type: :integer }, name: { type: :string }, status: { type: :string, enum: %w[available sold] }, customer: { '$ref' => '#/components/schemas/Customer' }, tags: { type: :array, items: { type: :string } }, attributes: { type: :object, additionalProperties: { type: :integer } }, released: { type: :string, format: :date }, updated: { type: :string, format: :'date-time' }, note: { type: :string, nullable: true }
  } },
  Receipt: { type: :object, required: %w[text count enabled tags fileName contentType bytes raw], properties: {
    text: { type: :string }, count: { type: :integer }, enabled: { type: :boolean }, tags: { type: :array, items: { type: :string } }, fileName: { type: :string }, contentType: { type: :string }, bytes: { type: :array, items: { type: :integer } }, raw: { type: :string }
  } },
  FormFields: { type: :object, required: ['text', 'count', 'enabled', 'tags[]'], properties: { text: { type: :string }, count: { type: :integer }, enabled: { type: :boolean }, 'tags[]' => { type: :array, items: { type: :string } } } },
  UploadFields: { type: :object, required: %w[file text count enabled], properties: { file: { type: :string, format: :binary }, text: { type: :string }, count: { type: :integer }, enabled: { type: :boolean } } },
  Card: { type: :object, required: %w[kind last4], properties: { kind: { type: :string, enum: ['card'] }, last4: { type: :string } } },
  Bank: { type: :object, required: %w[kind iban], properties: { kind: { type: :string, enum: ['bank'] }, iban: { type: :string } } },
  PaymentDocument: { type: :object, required: ['payment'], properties: { payment: { oneOf: [{ '$ref' => '#/components/schemas/Card' }, { '$ref' => '#/components/schemas/Bank' }], discriminator: { propertyName: 'kind', mapping: { card: '#/components/schemas/Card', bank: '#/components/schemas/Bank' } } } } },
  EmailContact: { type: :object, required: ['email'], properties: { email: { type: :string } } },
  PhoneContact: { type: :object, required: ['phone'], properties: { phone: { type: :string } } },
  ContactDocument: { type: :object, required: ['contact'], properties: { contact: { anyOf: [{ '$ref' => '#/components/schemas/EmailContact' }, { '$ref' => '#/components/schemas/PhoneContact' }] } } },
  Audit: { type: :object, required: ['source'], properties: { source: { type: :string } } },
  Details: { allOf: [{ '$ref' => '#/components/schemas/Product' }, { '$ref' => '#/components/schemas/Audit' }] },
  CustomerInput: { type: :object, required: %w[name secret], properties: { name: { type: :string }, secret: { type: :string, writeOnly: true } } },
  ApiError: { type: :object, required: ['detail'], properties: { detail: { type: :string } } }
}.freeze
