import 'package:test/test.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/object_decoder.dart';

void main() {
  group('ObjectDecoder', () {
    group('decodeObject with explode=true and ampersand separator', () {
      test('decodes simple key-value pairs', () {
        final result = 'name=John&age=30&city=NYC'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age', 'city'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John', 'age': '30', 'city': 'NYC'});
      });

      test('decodes single key-value pair', () {
        final result = 'name=John'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John'});
      });

      test('decodes with URI-encoded keys', () {
        final result = 'first%20name=John&last%20name=Doe'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'first name', 'last name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'first name': 'John', 'last name': 'Doe'});
      });

      test('decodes URI-encoded values with form style', () {
        final result = 'name=John%20Doe&email=test%40example.com'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'email'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John Doe', 'email': 'test@example.com'});
      });

      test('does not decode values with simple style', () {
        final result = 'name=John%20Doe&email=test%40example.com'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'email'},
          listKeys: {},
          isFormStyle: false,
        );

        expect(
          result,
          {'name': 'John%20Doe', 'email': 'test%40example.com'},
        );
      });

      test('handles empty values', () {
        final result = 'name=&age=30'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': '', 'age': '30'});
      });

      test('ignores unexpected keys', () {
        final result = 'name=John&unknown=value&age=30'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John', 'age': '30'});
      });

      test('ignores unexpected list properties and their items', () {
        final result = 'ids=1,2,3&tags=tag1,tag2,tag3'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'ids'},
          listKeys: {'ids'},
          isFormStyle: true,
        );

        expect(result, {'ids': '1,2,3'});
      });

      test('skips tokens without equals for forward compatibility', () {
        final result = 'name=John&invalidpair'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John'});
      });

      test('throws InvalidFormatException for multiple equals signs', () {
        expect(
          () => 'name=John=Doe'.decodeObject(
            explode: true,
            explodeSeparator: '&',
            expectedKeys: {'name'},
            listKeys: {},
            isFormStyle: true,
          ),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('passes context in exceptions', () {
        try {
          'name=John=Extra'.decodeObject(
            explode: true,
            explodeSeparator: '&',
            expectedKeys: {'name'},
            listKeys: {},
            isFormStyle: true,
            context: 'TestModel.fromForm',
          );
          fail('Should have thrown InvalidFormatException');
        } on InvalidFormatException catch (e) {
          expect(e, isA<InvalidFormatException>());
          expect(e.toString(), contains('TestModel.fromForm'));
        }
      });
    });

    group('decodeObject with explode=true and list values', () {
      test('decodes list values with semicolon separator', () {
        final result = 'numbers=1,2,3,4,5;strings=a,b,c,d,e,f;blub=asdf'
            .decodeObject(
              explode: true,
              explodeSeparator: ';',
              expectedKeys: {'numbers', 'strings', 'blub'},
              listKeys: {'numbers', 'strings'},
              isFormStyle: false,
            );

        expect(
          result,
          {'numbers': '1,2,3,4,5', 'strings': 'a,b,c,d,e,f', 'blub': 'asdf'},
        );
      });

      test('decodes list values with ampersand separator', () {
        final result = 'ids=1,2,3&names=john,jane,joe&count=42'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'ids', 'names', 'count'},
          listKeys: {'ids', 'names'},
          isFormStyle: true,
        );

        expect(
          result,
          {'ids': '1,2,3', 'names': 'john,jane,joe', 'count': '42'},
        );
      });

      test('decodes single list value', () {
        final result = 'numbers=1,2,3'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'numbers'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'numbers': '1,2,3'});
      });

      test('decodes empty list value', () {
        final result = 'numbers=&name=John'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'numbers', 'name'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'numbers': '', 'name': 'John'});
      });

      test('decodes mix of list and non-list properties', () {
        final result = 'id=123&tags=foo,bar,baz&name=Test&codes=A,B,C'
            .decodeObject(
              explode: true,
              explodeSeparator: '&',
              expectedKeys: {'id', 'tags', 'name', 'codes'},
              listKeys: {'tags', 'codes'},
              isFormStyle: false,
            );

        expect(
          result,
          {
            'id': '123',
            'tags': 'foo,bar,baz',
            'name': 'Test',
            'codes': 'A,B,C',
          },
        );
      });
    });

    group('decodeObject with explode=false and no lists', () {
      test('decodes alternating key-value pairs', () {
        final result = 'name,John,age,30,city,NYC'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age', 'city'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John', 'age': '30', 'city': 'NYC'});
      });

      test('decodes single key-value pair', () {
        final result = 'name,John'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John'});
      });

      test('decodes with URI-encoded keys', () {
        final result = 'first%20name,John,last%20name,Doe'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'first name', 'last name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'first name': 'John', 'last name': 'Doe'});
      });

      test('decodes URI-encoded values with form style', () {
        final result = 'name,John%20Doe,email,test%40example.com'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name', 'email'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John Doe', 'email': 'test@example.com'});
      });

      test('does not decode values with simple style', () {
        final result = 'name,John%20Doe,email,test%40example.com'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name', 'email'},
          listKeys: {},
          isFormStyle: false,
        );

        expect(
          result,
          {'name': 'John%20Doe', 'email': 'test%40example.com'},
        );
      });

      test('handles empty values', () {
        final result = 'name,,age,30'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': '', 'age': '30'});
      });

      test('ignores unexpected keys', () {
        final result = 'name,John,unknown,value,age,30'.decodeObject(
          explode: false,
          explodeSeparator: '&',
          expectedKeys: {'name', 'age'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'John', 'age': '30'});
      });

      test(
        'throws InvalidFormatException for odd number of parts without lists',
        () {
          expect(
            () => 'name,John,age'.decodeObject(
              explode: false,
              explodeSeparator: '&',
              expectedKeys: {'name', 'age'},
              listKeys: {},
              isFormStyle: true,
            ),
            throwsA(isA<InvalidFormatException>()),
          );
        },
      );
    });

    group('decodeObject with explode=false and list values', () {
      test('decodes list at end of properties', () {
        final result = 'blub,asdf,numbers,1,2,3,4,5'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'blub', 'numbers'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'blub': 'asdf', 'numbers': '1,2,3,4,5'});
      });

      test('decodes list in middle of properties', () {
        final result = 'numbers,1,2,3,4,5,strings,a,b,c,d,e,f,blub,asdf'
            .decodeObject(
              explode: false,
              explodeSeparator: ',',
              expectedKeys: {'numbers', 'strings', 'blub'},
              listKeys: {'numbers', 'strings'},
              isFormStyle: false,
            );

        expect(
          result,
          {'numbers': '1,2,3,4,5', 'strings': 'a,b,c,d,e,f', 'blub': 'asdf'},
        );
      });

      test('decodes single list property', () {
        final result = 'numbers,1,2,3,4,5'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'numbers'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'numbers': '1,2,3,4,5'});
      });

      test('decodes mix of list and non-list properties', () {
        final result = 'id,123,tags,foo,bar,baz,name,Test'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'id', 'tags', 'name'},
          listKeys: {'tags'},
          isFormStyle: false,
        );

        expect(result, {'id': '123', 'tags': 'foo,bar,baz', 'name': 'Test'});
      });

      test('decodes multiple consecutive lists', () {
        final result = 'nums,1,2,3,letters,a,b,c,value,end'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'nums', 'letters', 'value'},
          listKeys: {'nums', 'letters'},
          isFormStyle: false,
        );

        expect(result, {'nums': '1,2,3', 'letters': 'a,b,c', 'value': 'end'});
      });

      test('decodes list with single item', () {
        final result = 'name,John,numbers,42,age,30'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'name', 'numbers', 'age'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'name': 'John', 'numbers': '42', 'age': '30'});
      });

      test('decodes empty list value', () {
        final result = 'numbers,,name,John'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'numbers', 'name'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'numbers': '', 'name': 'John'});
      });

      test('decodes list with URI-encoded values', () {
        final result = 'tags,foo%20bar,baz%20qux,quux,id,123'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'tags', 'id'},
          listKeys: {'tags'},
          isFormStyle: true,
        );

        expect(result, {'tags': 'foo bar,baz qux,quux', 'id': '123'});
      });

      test('treats non-key values in list as list items', () {
        final result = 'numbers,1,2,unknown,4,5'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'numbers'},
          listKeys: {'numbers'},
          isFormStyle: false,
        );

        expect(result, {'numbers': '1,2,unknown,4,5'});
      });
    });

    group('decodeObject with null or empty input', () {
      test('throws InvalidFormatException for null input', () {
        expect(
          () => (null as String?).decodeObject(
            explode: true,
            explodeSeparator: '&',
            expectedKeys: {'name'},
            listKeys: {},
            isFormStyle: true,
          ),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('throws InvalidFormatException for empty string', () {
        expect(
          () => ''.decodeObject(
            explode: true,
            explodeSeparator: '&',
            expectedKeys: {'name'},
            listKeys: {},
            isFormStyle: true,
          ),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('includes context in null/empty exceptions', () {
        try {
          (null as String?).decodeObject(
            explode: true,
            explodeSeparator: '&',
            expectedKeys: {'name'},
            listKeys: {},
            isFormStyle: true,
            context: 'TestModel.fromForm',
          );
          fail('Should have thrown InvalidFormatException');
        } on InvalidFormatException catch (e) {
          expect(e.toString(), contains('TestModel.fromForm'));
        }
      });
    });

    group('decodeObject with special characters', () {
      test('handles values with encoded separators', () {
        final result = 'url=http%3A%2F%2Fexample.com&port=8080'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'url', 'port'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'url': 'http://example.com', 'port': '8080'});
      });

      test('handles values with equals signs when properly encoded', () {
        final result = 'formula=a%3Db%2Bc&result=42'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'formula', 'result'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'formula': 'a=b+c', 'result': '42'});
      });

      test('handles unicode characters', () {
        final result = 'name=M%C3%BCller&city=Z%C3%BCrich'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'city'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'name': 'Müller', 'city': 'Zürich'});
      });

      test('handles emoji in values', () {
        final result = 'emoji=%F0%9F%98%80&name=John'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'emoji', 'name'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result, {'emoji': '😀', 'name': 'John'});
      });
    });

    group('decodeObject complete scenarios', () {
      test('form style exploded with lists', () {
        final result = 'ids=1,2,3&names=john,jane,joe&count=42'.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'ids', 'names', 'count'},
          listKeys: {'ids', 'names'},
          isFormStyle: true,
        );

        expect(
          result,
          {'ids': '1,2,3', 'names': 'john,jane,joe', 'count': '42'},
        );
      });

      test('simple style exploded with lists', () {
        final result = 'ids=1,2,3,names=a,b,c,count=5'.decodeObject(
          explode: true,
          explodeSeparator: ',',
          expectedKeys: {'ids', 'names', 'count'},
          listKeys: {'ids', 'names'},
          isFormStyle: false,
        );

        expect(result, {'ids': '1,2,3', 'names': 'a,b,c', 'count': '5'});
      });

      test(
        'simple style exploded skips unexpected list items for forward '
        'compatibility',
        () {
          final result = 'ids=1,2,3,tags=tag1,tag2,tag3'.decodeObject(
            explode: true,
            explodeSeparator: ',',
            expectedKeys: {'ids'},
            listKeys: {'ids'},
            isFormStyle: false,
          );

          expect(result, {'ids': '1,2,3'});
        },
      );

      test('form style non-exploded with lists', () {
        final result = 'id,123,tags,foo,bar,baz,name,Test'.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'id', 'tags', 'name'},
          listKeys: {'tags'},
          isFormStyle: true,
        );

        expect(result, {'id': '123', 'tags': 'foo,bar,baz', 'name': 'Test'});
      });

      test('simple style non-exploded with lists', () {
        final result = 'numbers,1,2,3,4,5,strings,a,b,c,d,e,f,blub,asdf'
            .decodeObject(
              explode: false,
              explodeSeparator: ',',
              expectedKeys: {'numbers', 'strings', 'blub'},
              listKeys: {'numbers', 'strings'},
              isFormStyle: false,
            );

        expect(
          result,
          {'numbers': '1,2,3,4,5', 'strings': 'a,b,c,d,e,f', 'blub': 'asdf'},
        );
      });

      test('complex scenario with encoded values and lists', () {
        final result =
            'first%20name,John%20Doe,tags,work,home,email,test%40example.com'
                .decodeObject(
                  explode: false,
                  explodeSeparator: ',',
                  expectedKeys: {'first name', 'tags', 'email'},
                  listKeys: {'tags'},
                  isFormStyle: true,
                );

        expect(
          result,
          {
            'first name': 'John Doe',
            'tags': 'work,home',
            'email': 'test@example.com',
          },
        );
      });
    });

    group('Binary', () {
      test('decodes binary string values in exploded objects', () {
        const input = 'name=test&data=Hello+World';
        final result = input.decodeObject(
          explode: true,
          explodeSeparator: '&',
          expectedKeys: {'name', 'data'},
          listKeys: {},
          isFormStyle: true,
        );

        expect(result['name'], 'test');
        expect(result['data'], 'Hello World');
      });

      test('decodes binary string values in non-exploded objects', () {
        const input = 'name,test,data,Hello World';
        final result = input.decodeObject(
          explode: false,
          explodeSeparator: ',',
          expectedKeys: {'name', 'data'},
          listKeys: {},
          isFormStyle: false,
        );

        expect(result['name'], 'test');
        expect(result['data'], 'Hello World');
      });
    });
  });
}
