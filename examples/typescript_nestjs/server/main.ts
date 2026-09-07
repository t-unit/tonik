import 'reflect-metadata';
import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Module,
  Param,
  ParseBoolPipe,
  ParseIntPipe,
  Post,
  Query,
  Req,
  Res,
  UploadedFile,
  UseInterceptors,
  ValidationPipe,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiExtraModels,
  ApiHeader,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiProduces,
  ApiProperty,
  ApiQuery,
  ApiTags,
  DocumentBuilder,
  getSchemaPath,
  SwaggerModule,
} from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';
import express, { Request, Response } from 'express';
import cookieParser from 'cookie-parser';
import compression from 'compression';
import iconv from 'iconv-lite';

class Customer {
  @ApiProperty({ format: 'uuid' }) id: string;
  @ApiProperty() name: string;
}

class Product {
  @ApiProperty({ type: 'integer' }) id: number;
  @ApiProperty() @IsString() name: string;
  @ApiProperty({ enum: ['available', 'sold'] }) status: string;
  @ApiProperty({ type: Customer }) customer: Customer;
  @ApiProperty({ type: [String] }) tags: string[];
  @ApiProperty({ type: 'object', additionalProperties: { type: 'integer' } })
  attributes: Record<string, number>;
  @ApiProperty({ type: 'string', format: 'date' }) released: string;
  @ApiProperty({ type: 'string', format: 'date-time' }) updated: string;
  @ApiProperty({ type: String, nullable: true }) note: string | null;
}

class Receipt {
  @ApiProperty() text: string;
  @ApiProperty({ type: 'integer' }) count: number;
  @ApiProperty() enabled: boolean;
  @ApiProperty({ type: [String] }) tags: string[];
  @ApiProperty() fileName: string;
  @ApiProperty() contentType: string;
  @ApiProperty({ type: 'array', items: { type: 'integer' } }) bytes: number[];
  @ApiProperty() raw: string;
}

class FormFields {
  @ApiProperty() text: string;
  @ApiProperty({ type: 'integer' }) count: number;
  @ApiProperty() enabled: boolean;
  @ApiProperty({ type: [String] }) tags: string[];
}

class UploadFields {
  @ApiProperty({ type: 'string', format: 'binary' }) file: unknown;
  @ApiProperty() text: string;
  @ApiProperty({ type: 'integer' }) count: number;
  @ApiProperty() enabled: boolean;
}

class Card {
  @ApiProperty({ enum: ['card'] }) kind: string;
  @ApiProperty() last4: string;
}

class Bank {
  @ApiProperty({ enum: ['bank'] }) kind: string;
  @ApiProperty() iban: string;
}

class PaymentDocument {
  @ApiProperty({
    oneOf: [{ $ref: getSchemaPath(Card) }, { $ref: getSchemaPath(Bank) }],
    discriminator: {
      propertyName: 'kind',
      mapping: { card: getSchemaPath(Card), bank: getSchemaPath(Bank) },
    },
  })
  payment: Card | Bank;
}

class EmailContact {
  @ApiProperty() email: string;
}

class PhoneContact {
  @ApiProperty() phone: string;
}

class ContactDocument {
  @ApiProperty({
    anyOf: [
      { $ref: getSchemaPath(EmailContact) },
      { $ref: getSchemaPath(PhoneContact) },
    ],
  })
  contact: EmailContact | PhoneContact;
}

class Audit {
  @ApiProperty() source: string;
}

class CustomerInput {
  @ApiProperty() @IsString() @IsNotEmpty() name: string;
  @ApiProperty({ writeOnly: true }) @IsString() secret: string;
}

class ApiError {
  @ApiProperty() detail: string;
}
const product: Product = {
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
const empty: Receipt = {
  text: '',
  count: 0,
  enabled: false,
  tags: [],
  fileName: '',
  contentType: '',
  bytes: [],
  raw: '',
};

@ApiTags('Catalog')
@ApiExtraModels(Card, Bank, EmailContact, PhoneContact, Product, Audit)
@Controller()
class CatalogController {
  @Get('products/42')
  @ApiOperation({ operationId: 'jsonProduct' })
  @ApiOkResponse({ type: Product })
  product() {
    return product;
  }

  @Post('products/echo')
  @HttpCode(200)
  @ApiOperation({ operationId: 'echoProduct' })
  @ApiOkResponse({ type: Product })
  echoProduct(@Body() body: Product) {
    return body;
  }

  @Get('products/42/details')
  @ApiOperation({ operationId: 'details' })
  @ApiOkResponse({
    schema: {
      allOf: [{ $ref: getSchemaPath(Product) }, { $ref: getSchemaPath(Audit) }],
    },
  })
  details() {
    return { ...product, source: 'fixture' };
  }

  @Get('inspect/:key')
  @ApiOperation({ operationId: 'inspect' })
  @ApiQuery({ name: 'count', type: 'integer' })
  @ApiQuery({ name: 'enabled', type: Boolean })
  @ApiQuery({ name: 'tags', type: [String], style: 'form', explode: true })
  @ApiHeader({ name: 'x-trace', required: true })
  @ApiHeader({ name: 'Cookie', required: true })
  @ApiOkResponse({ type: Receipt })
  inspect(
    @Param('key') key: string,
    @Query('count', ParseIntPipe) count: number,
    @Query('enabled', ParseBoolPipe) enabled: boolean,
    @Query('tags') tags: string[] | string,
    @Headers('x-trace') trace: string,
    @Req() request: Request,
  ): Receipt {
    return {
      ...empty,
      text: key,
      count,
      enabled,
      tags: typeof tags === 'string' ? [tags] : tags,
      contentType: trace,
      fileName: request.cookies.session,
      raw: request.originalUrl.split('?')[1] ?? '',
    };
  }

  @Post('forms/echo')
  @HttpCode(200)
  @ApiOperation({ operationId: 'form' })
  @ApiConsumes('application/x-www-form-urlencoded')
  @ApiBody({ type: FormFields })
  @ApiOkResponse({ type: Receipt })
  form(
    @Body() body: FormFields,
    @Req() request: Request & { rawForm?: string },
  ): Receipt {
    return {
      ...empty,
      text: body.text,
      count: Number(body.count),
      enabled: String(body.enabled) === 'true',
      tags: Array.isArray(body.tags) ? body.tags : [body.tags],
      contentType: request.headers['content-type']!,
      raw: request.rawForm!,
    };
  }

  @Post('uploads')
  @HttpCode(200)
  @ApiOperation({ operationId: 'upload' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ type: UploadFields })
  @ApiOkResponse({ type: Receipt })
  @UseInterceptors(FileInterceptor('file'))
  upload(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadFields,
  ): Receipt {
    if (!file) throw new BadRequestException('file is required');
    return {
      ...empty,
      text: body.text,
      count: Number(body.count),
      enabled: String(body.enabled) === 'true',
      fileName: file.originalname,
      contentType: file.mimetype,
      bytes: Array.from(file.buffer),
    };
  }

  @Get('files/sample')
  @ApiOperation({ operationId: 'binary' })
  @ApiProduces('application/octet-stream')
  @ApiOkResponse({ schema: { type: 'string', format: 'binary' } })
  binary(@Res() response: Response) {
    response
      .type('application/octet-stream')
      .send(Buffer.from([0, 1, 127, 128, 255]));
  }

  @Post('files/echo')
  @HttpCode(200)
  @ApiOperation({ operationId: 'echoBinary' })
  @ApiConsumes('application/octet-stream')
  @ApiBody({ schema: { type: 'string', format: 'binary' } })
  @ApiProduces('application/octet-stream')
  @ApiOkResponse({ schema: { type: 'string', format: 'binary' } })
  echoBinary(@Body() body: Buffer, @Res() response: Response) {
    response.type('application/octet-stream').send(body);
  }

  @Get('text/:encoding')
  @ApiOperation({ operationId: 'text' })
  @ApiProduces('text/plain')
  @ApiOkResponse({ schema: { type: 'string' } })
  text(@Param('encoding') encoding: string, @Res() response: Response) {
    const [value, charset] = (
      {
        utf8: ['Grüße, 東京 👋', 'utf-8'],
        latin1: ['café', 'iso-8859-1'],
        windows1252: ['€ café', 'windows-1252'],
        'shift-jis': ['東京', 'shift_jis'],
      } as Record<string, string[]>
    )[encoding];
    response.setHeader('Content-Type', 'text/plain; charset=' + charset);
    response.send(iconv.encode(value, charset));
  }

  @Get('payments/:kind')
  @ApiOperation({ operationId: 'payment' })
  @ApiOkResponse({ type: PaymentDocument })
  payment(@Param('kind') kind: string): PaymentDocument {
    return {
      payment:
        kind === 'card'
          ? { kind: 'card', last4: '4242' }
          : { kind: 'bank', iban: 'DE02120300000000202051' },
    };
  }

  @Post('payments/echo')
  @HttpCode(200)
  @ApiOperation({ operationId: 'echoPayment' })
  @ApiOkResponse({ type: PaymentDocument })
  echoPayment(@Body() body: PaymentDocument) {
    const payment = body.payment;
    if (payment.kind === 'card' && 'last4' in payment && !('iban' in payment))
      return body;
    if (payment.kind === 'bank' && 'iban' in payment && !('last4' in payment))
      return body;
    throw new BadRequestException('Expected one card or bank payment');
  }

  @Post('contacts/echo')
  @HttpCode(200)
  @ApiOperation({ operationId: 'contact' })
  @ApiOkResponse({ type: ContactDocument })
  contact(@Body() body: ContactDocument) {
    if (!('email' in body.contact) && !('phone' in body.contact))
      throw new BadRequestException('email or phone is required');
    return body;
  }

  @Post('customers')
  @ApiOperation({ operationId: 'createCustomer' })
  @ApiCreatedResponse({ type: Customer })
  createCustomer(@Body() body: CustomerInput): Customer {
    return { id: product.customer.id, name: body.name };
  }

  @Delete('products/42')
  @HttpCode(204)
  @ApiOperation({ operationId: 'deleteProduct' })
  @ApiNoContentResponse()
  deleteProduct() {}

  @Get('missing')
  @HttpCode(404)
  @ApiOperation({ operationId: 'missing' })
  @ApiNotFoundResponse({ type: ApiError })
  missing(): ApiError {
    return { detail: 'Product not found' };
  }
}
@Module({ controllers: [CatalogController] })
class CatalogModule {}

async function main() {
  const app = await NestFactory.create(CatalogModule, { bodyParser: false });
  app.use(express.json());
  app.use(
    express.urlencoded({
      extended: false,
      verify: (request, response, buffer) => {
        (request as Request & { rawForm?: string }).rawForm =
          buffer.toString('utf8');
      },
    }),
  );
  app.use(express.raw({ type: 'application/octet-stream' }));
  app.use(cookieParser());
  app.use(compression({ threshold: 1 }));
  app.useGlobalPipes(new ValidationPipe({ transform: true }));
  const config = new DocumentBuilder()
    .setTitle('NestJS catalog')
    .setVersion('1.0.0')
    .addServer('http://localhost')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  const server = app.getHttpAdapter().getInstance();
  server.get('/health', (request: Request, response: Response) =>
    response.json({ ok: true }),
  );
  server.get('/openapi.json', (request: Request, response: Response) =>
    response.json(document),
  );
  await app.listen(8000, '0.0.0.0');
}
void main();
