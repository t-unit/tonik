import 'package:adversarial_strings_api/adversarial_strings_api.dart';
import 'package:test/test.dart';

void main() {
  group('static server URL with single quote', () {
    test('baseUrl preserves the single quote', () {
      final server = ApiOreillyServer();
      expect(server.baseUrl, "https://api.o'reilly.example.com/v1");
    });
  });

  group('templated server URL with single quote', () {
    test('baseUrl preserves the single quote with default variable', () {
      final server = ItsABenv7DServer();
      expect(server.baseUrl, "https://it's-a-prod.example.com/v1");
    });

    test('baseUrl preserves the single quote with custom variable', () {
      final server = ItsABenv7DServer(env: 'staging');
      expect(server.baseUrl, "https://it's-a-staging.example.com/v1");
    });
  });

  group('oneOf with quoted discriminator values', () {
    test('toJson includes quoted discriminator value', () {
      final result = QuotedOneOfSuccessResult(
        SuccessResult(value: 'ok'),
      );
      final json = result.toJson()! as Map<String, Object?>;
      expect(json['type'], "it's-success");
      expect(json['value'], 'ok');
    });

    test('fromJson dispatches on quoted discriminator value', () {
      final json = <String, Object?>{
        'type': "it's-success",
        'value': 'ok',
      };
      final result = QuotedOneOf.fromJson(json);
      expect(result, isA<QuotedOneOfSuccessResult>());
      final success = (result as QuotedOneOfSuccessResult).value;
      expect(success.value, 'ok');
    });

    test('json round-trip preserves quoted discriminator', () {
      final original = QuotedOneOfErrorResult(
        ErrorResult(message: 'fail'),
      );
      final json = original.toJson();
      final reconstructed = QuotedOneOf.fromJson(json);
      expect(reconstructed, isA<QuotedOneOfErrorResult>());
      final error = (reconstructed as QuotedOneOfErrorResult).value;
      expect(error.message, 'fail');
    });
  });

  group('anyOf with quoted discriminator values', () {
    test('toJson includes quoted discriminator value in map', () {
      final model = QuotedAnyOf(personModel: PersonModel(name: 'Alice'));
      final json = model.toJson()! as Map<String, Object?>;
      expect(json['kind'], "it's-person");
      expect(json['name'], 'Alice');
    });

    test('toJson includes different quoted discriminator for other variant',
        () {
      final model = QuotedAnyOf(companyModel: CompanyModel(title: 'Acme'));
      final json = model.toJson()! as Map<String, Object?>;
      expect(json['kind'], "it's-company");
      expect(json['title'], 'Acme');
    });
  });

  group('anyOf with quoted discriminator field name', () {
    test('toJson uses quoted field name as map key', () {
      final model = QuotedDiscriminatorField(
        personModel: PersonModel(name: 'Bob'),
      );
      final json = model.toJson()! as Map<String, Object?>;
      expect(json["it's-type"], 'person');
      expect(json['name'], 'Bob');
    });

    test('toJson uses quoted field name for other variant', () {
      final model = QuotedDiscriminatorField(
        companyModel: CompanyModel(title: 'Corp'),
      );
      final json = model.toJson()! as Map<String, Object?>;
      expect(json["it's-type"], 'company');
      expect(json['title'], 'Corp');
    });
  });

  group('oneOf with both single and double quotes in discriminator', () {
    test('toJson includes discriminator with both quote types', () {
      final result = BothQuotesOneOfSuccessResult(
        SuccessResult(value: 'ok'),
      );
      final json = result.toJson()! as Map<String, Object?>;
      expect(json['type'], 'it\'s a "success"');
    });

    test('fromJson dispatches on discriminator with both quote types', () {
      final json = <String, Object?>{
        'type': 'it\'s a "success"',
        'value': 'ok',
      };
      final result = BothQuotesOneOf.fromJson(json);
      expect(result, isA<BothQuotesOneOfSuccessResult>());
    });

    test('json round-trip with both quote types', () {
      final original = BothQuotesOneOfErrorResult(
        ErrorResult(message: 'fail'),
      );
      final json = original.toJson();
      final reconstructed = BothQuotesOneOf.fromJson(json);
      expect(reconstructed, isA<BothQuotesOneOfErrorResult>());
    });
  });

  group('oneOf with triple-double-quotes in discriminator', () {
    test('toJson includes discriminator with triple quotes', () {
      final result = TripleQuoteOneOfSuccessResult(
        SuccessResult(value: 'ok'),
      );
      final json = result.toJson()! as Map<String, Object?>;
      expect(json['type'], 'it\'s a """success"""');
    });

    test('fromJson dispatches on discriminator with triple quotes', () {
      final json = <String, Object?>{
        'type': 'it\'s a """success"""',
        'value': 'ok',
      };
      final result = TripleQuoteOneOf.fromJson(json);
      expect(result, isA<TripleQuoteOneOfSuccessResult>());
    });
  });

  group('object with double-quote in property name', () {
    test('toJson uses double-quoted property key', () {
      final obj = ObjectWithDoubleQuoteProp(id: 'x', fieldname: 'val');
      final json = obj.toJson()! as Map<String, Object?>;
      expect(json['id'], 'x');
      expect(json['field"name'], 'val');
    });

    test('fromJson reads double-quoted property key', () {
      final json = <String, Object?>{'id': 'x', 'field"name': 'val'};
      final obj = ObjectWithDoubleQuoteProp.fromJson(json);
      expect(obj.id, 'x');
      expect(obj.fieldname, 'val');
    });

    test('json round-trip with double-quoted property key', () {
      final original = ObjectWithDoubleQuoteProp(
        id: 'rt',
        fieldname: 'test',
      );
      final json = original.toJson();
      final reconstructed = ObjectWithDoubleQuoteProp.fromJson(json);
      expect(reconstructed.id, 'rt');
      expect(reconstructed.fieldname, 'test');
    });
  });

  group('object with quoted property name', () {
    test('toJson uses quoted property key', () {
      final obj = ObjectWithQuotedProp(id: 'x');
      final json = obj.toJson()! as Map<String, Object?>;
      expect(json['id'], 'x');
    });

    test('fromJson reads quoted property key', () {
      final json = <String, Object?>{'id': 'test-id'};
      final obj = ObjectWithQuotedProp.fromJson(json);
      expect(obj.id, 'test-id');
    });

    test('json round-trip preserves id through quoted schema', () {
      final original = ObjectWithQuotedProp(id: 'round-trip');
      final json = original.toJson();
      final reconstructed = ObjectWithQuotedProp.fromJson(json);
      expect(reconstructed.id, 'round-trip');
    });
  });
}
