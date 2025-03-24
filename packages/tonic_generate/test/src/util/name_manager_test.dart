import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('NameManger', () {
    late NameGenerator generator;
    late NameManger manager;

    setUp(() {
      generator = NameGenerator();
      manager = NameManger(generator: generator);
    });

    test('caches generated names', () {
      const tag = Tag(name: 'pets');

      final name1 = manager.tagName(tag);
      final name2 = manager.tagName(tag);

      expect(name1, 'PetsApi');
      expect(name2, 'PetsApi', reason: 'Should return cached name');
    });

    test('primes names in correct order', () {
      final context = Context.initial();

      final models = [
        ListModel(content: StringModel(context: context), context: context),
        ListModel(content: StringModel(context: context), context: context),
      ];
      final responses = [
        Response(
          name: 'user',
          context: context,
          description: 'A user response',
          headers: const {},
        ),
        Response(
          name: 'user',
          context: context,
          description: 'Another user response',
          headers: const {},
        ),
      ];
      const tags = [Tag(name: 'user')];

      manager.prime(
        models: models,
        responses: responses,
        responseHeaders: const [],
        operations: const [],
        requestHeaders: const [],
        queryParameters: const [],
        pathParameters: const [],
        tags: tags,
      );

      // First model gets Anonymous
      expect(manager.modelName(models[0]), 'Anonymous');
      // Second model gets Model suffix
      expect(manager.modelName(models[1]), 'AnonymousModel');

      // First response gets base name
      expect(manager.responseName(responses[0]), 'User');
      // Second response gets Response suffix
      expect(manager.responseName(responses[1]), 'UserResponse');

      // First tag gets Api suffix immediately
      expect(manager.tagName(tags[0]), 'UserApi');
    });
  });
}
