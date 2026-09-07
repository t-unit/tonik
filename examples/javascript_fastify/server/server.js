import { Transform } from 'node:stream';
import Fastify from 'fastify';
import swagger from '@fastify/swagger';
import multipart, { ajvFilePlugin } from '@fastify/multipart';
import formbody from '@fastify/formbody';
import compress from '@fastify/compress';
import iconv from 'iconv-lite';

const app = Fastify({
  logger: true,
  ajv: { customOptions: { discriminator: true }, plugins: [ajvFilePlugin] },
});
await app.register(swagger, {
  refResolver: { buildLocalReference: (json) => json.$id },
  openapi: {
    openapi: '3.0.3',
    info: { title: 'Fastify catalog', version: '1.0.0' },
    servers: [{ url: 'http://localhost' }],
  },
});
await app.register(formbody);
await app.register(compress, { threshold: 1 });
await app.register(multipart, {
  attachFieldsToBody: 'keyValues',
  async onFile(part) {
    part.value = {
      file: part.file,
      fileName: part.filename,
      contentType: part.mimetype,
      bytes: Array.from(await part.toBuffer()),
    };
  },
});
app.addHook('preParsing', async (request, reply, payload) => {
  if (
    !request.headers['content-type']?.startsWith(
      'application/x-www-form-urlencoded',
    )
  )
    return payload;
  // Return a Transform so bytes remain buffered until Fastify attaches its parser.
  // receivedEncodedLength is the byte count Fastify uses for Content-Length checks.
  const chunks = [];
  const tee = new Transform({
    transform(chunk, encoding, callback) {
      chunks.push(chunk);
      this.receivedEncodedLength += chunk.length;
      callback(null, chunk);
    },
    flush(callback) {
      request.rawForm = Buffer.concat(chunks).toString('utf8');
      callback();
    },
  });
  tee.receivedEncodedLength = 0;
  return payload.pipe(tee);
});

const string = { type: 'string' };
const integer = { type: 'integer' };
const boolean = { type: 'boolean' };
const strings = { type: 'array', items: string };
const ref = (name) => ({ $ref: name + '#' });
const object = (properties, required = Object.keys(properties)) => ({
  type: 'object',
  properties,
  required,
});
app.addSchema({
  $id: 'Customer',
  ...object({ id: { type: 'string', format: 'uuid' }, name: string }),
});
app.addSchema({
  $id: 'Product',
  ...object({
    id: integer,
    name: string,
    status: { type: 'string', enum: ['available', 'sold'] },
    customer: ref('Customer'),
    tags: strings,
    attributes: { type: 'object', additionalProperties: integer },
    released: { type: 'string', format: 'date' },
    updated: { type: 'string', format: 'date-time' },
    note: { type: 'string', nullable: true },
  }),
});
app.addSchema({
  $id: 'Receipt',
  ...object({
    text: string,
    count: integer,
    enabled: boolean,
    tags: strings,
    fileName: string,
    contentType: string,
    bytes: { type: 'array', items: integer },
    raw: string,
  }),
});
app.addSchema({
  $id: 'Card',
  ...object({ kind: { type: 'string', enum: ['card'] }, last4: string }),
});
app.addSchema({
  $id: 'Bank',
  ...object({ kind: { type: 'string', enum: ['bank'] }, iban: string }),
});
app.addSchema({
  $id: 'PaymentDocument',
  ...object({
    payment: {
      oneOf: [ref('Card'), ref('Bank')],
      discriminator: { propertyName: 'kind' },
    },
  }),
});
app.addSchema({
  $id: 'EmailContact',
  ...object({ email: string }, ['email']),
  additionalProperties: true,
});
app.addSchema({
  $id: 'PhoneContact',
  ...object({ phone: string }, ['phone']),
  additionalProperties: true,
});
app.addSchema({
  $id: 'ContactDocument',
  ...object({ contact: { anyOf: [ref('EmailContact'), ref('PhoneContact')] } }),
});
app.addSchema({ $id: 'Audit', ...object({ source: string }) });
app.addSchema({ $id: 'Details', allOf: [ref('Product'), ref('Audit')] });
app.addSchema({
  $id: 'CustomerInput',
  ...object({ name: string, secret: { type: 'string', writeOnly: true } }),
});
app.addSchema({ $id: 'Error', ...object({ detail: string }) });
const product = {
  id: 42,
  name: 'Tea & café',
  status: 'available',
  customer: { id: '123e4567-e89b-12d3-a456-426614174000', name: 'Ada Example' },
  tags: ['tea', '東京'],
  attributes: { stock: 7 },
  released: '2025-01-02',
  updated: '2025-01-02T03:04:05+02:00',
  note: null,
};
const receipt = {
  text: '',
  count: 0,
  enabled: false,
  tags: [],
  fileName: '',
  contentType: '',
  bytes: [],
  raw: '',
};
const schema = (operationId, response, extra = {}) => ({
  operationId,
  tags: ['Catalog'],
  response: { 200: response },
  ...extra,
});
app.get('/health', { schema: { hide: true } }, async () => ({ ok: true }));
app.get('/openapi.json', { schema: { hide: true } }, async () => app.swagger());
app.get(
  '/products/42',
  { schema: schema('jsonProduct', ref('Product')) },
  async () => product,
);
app.post(
  '/products/echo',
  { schema: schema('echoProduct', ref('Product'), { body: ref('Product') }) },
  async (request) => request.body,
);
app.get(
  '/products/42/details',
  { schema: schema('details', ref('Details')) },
  async () => ({ ...product, source: 'fixture' }),
);
app.get(
  '/inspect/:key',
  {
    schema: schema('inspect', ref('Receipt'), {
      params: object({ key: string }),
      querystring: object({ count: integer, enabled: boolean, tags: strings }),
      headers: object({ 'x-trace': string, session: string }),
    }),
  },
  async (request) => ({
    ...receipt,
    text: request.params.key,
    count: request.query.count,
    enabled: request.query.enabled,
    tags: request.query.tags,
    contentType: request.headers['x-trace'],
    fileName: request.headers.session,
    raw: request.raw.url.split('?')[1] ?? '',
  }),
);
app.post(
  '/forms/echo',
  {
    schema: schema('form', ref('Receipt'), {
      consumes: ['application/x-www-form-urlencoded'],
      body: object({
        text: string,
        count: integer,
        enabled: boolean,
        tags: strings,
      }),
    }),
  },
  async (request) => ({
    ...receipt,
    ...request.body,
    contentType: request.headers['content-type'],
    raw: request.rawForm,
  }),
);
app.post(
  '/uploads',
  {
    schema: schema('upload', ref('Receipt'), {
      consumes: ['multipart/form-data'],
      body: object({
        file: { isFile: true },
        text: string,
        count: integer,
        enabled: boolean,
      }),
    }),
  },
  async (request) => ({
    ...receipt,
    text: request.body.text,
    count: request.body.count,
    enabled: request.body.enabled,
    ...request.body.file,
  }),
);
app.addContentTypeParser(
  'application/octet-stream',
  { parseAs: 'buffer' },
  (request, body, done) => done(null, body),
);
app.get(
  '/files/sample',
  {
    schema: schema(
      'binary',
      { type: 'string', format: 'binary' },
      { produces: ['application/octet-stream'] },
    ),
  },
  async (request, reply) =>
    reply
      .type('application/octet-stream')
      .send(Buffer.from([0, 1, 127, 128, 255])),
);
app.post(
  '/files/echo',
  {
    schema: schema(
      'echoBinary',
      { type: 'string', format: 'binary' },
      {
        consumes: ['application/octet-stream'],
        produces: ['application/octet-stream'],
        body: { type: 'string', format: 'binary' },
      },
    ),
    attachValidation: true,
  },
  async (request, reply) => {
    if (!Buffer.isBuffer(request.body))
      return reply.code(400).send({ detail: 'Expected binary bytes' });
    return reply.type('application/octet-stream').send(request.body);
  },
);
app.get(
  '/text/:encoding',
  {
    schema: schema('text', string, {
      params: object({ encoding: string }),
      produces: ['text/plain'],
    }),
  },
  async (request, reply) => {
    const [value, charset] = {
      utf8: ['Grüße, 東京 👋', 'utf-8'],
      latin1: ['café', 'iso-8859-1'],
      windows1252: ['€ café', 'windows-1252'],
      'shift-jis': ['東京', 'shift_jis'],
    }[request.params.encoding];
    return reply
      .type('text/plain; charset=' + charset)
      .send(iconv.encode(value, charset));
  },
);
app.get(
  '/payments/:kind',
  {
    schema: schema('payment', ref('PaymentDocument'), {
      params: object({ kind: string }),
    }),
  },
  async (request) => ({
    payment:
      request.params.kind === 'card'
        ? { kind: 'card', last4: '4242' }
        : { kind: 'bank', iban: 'DE02120300000000202051' },
  }),
);
app.post(
  '/payments/echo',
  {
    schema: schema('echoPayment', ref('PaymentDocument'), {
      body: ref('PaymentDocument'),
    }),
  },
  async (request) => request.body,
);
app.post(
  '/contacts/echo',
  {
    schema: schema('contact', ref('ContactDocument'), {
      body: ref('ContactDocument'),
    }),
  },
  async (request) => request.body,
);
app.post(
  '/customers',
  {
    schema: {
      operationId: 'createCustomer',
      tags: ['Catalog'],
      body: ref('CustomerInput'),
      response: { 201: ref('Customer') },
    },
  },
  async (request, reply) =>
    reply.code(201).send({ id: product.customer.id, name: request.body.name }),
);
app.delete(
  '/products/42',
  {
    schema: {
      operationId: 'deleteProduct',
      tags: ['Catalog'],
      response: { 204: { type: 'null' } },
    },
  },
  async (request, reply) => reply.code(204).send(),
);
app.get(
  '/missing',
  {
    schema: {
      operationId: 'missing',
      tags: ['Catalog'],
      response: { 404: ref('Error') },
    },
  },
  async (request, reply) =>
    reply.code(404).send({ detail: 'Product not found' }),
);
await app.listen({ host: '0.0.0.0', port: 8000 });
