import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

/// Generates operation-local helpers needed to merge repeated multipart
/// properties. These methods are emitted only for operations that use them.
Iterable<Method> generateMultipartMergeMethods(RequestBodyPlan body) sync* {
  final helpers = _mergeHelpers(body);
  if (helpers.contains(MultipartMergeHelper.lists)) {
    yield _mergeListsMethod();
  }
  if (helpers.contains(MultipartMergeHelper.propertyValues)) {
    yield _mergePropertyValuesMethod();
    yield _mergePropertyValueMethod();
  }
  if (helpers.contains(MultipartMergeHelper.dynamicValues)) {
    yield _mergeValuesMethod();
    yield _mergeMapMethod();
  }
}

final Reference _string = refer('String', 'dart:core');
final Reference _dynamic = refer('dynamic', 'dart:core');
final Reference _propertyValue = refer(
  'PropertyValue',
  'package:tonik_util/tonik_util.dart',
);

Set<MultipartMergeHelper> _mergeHelpers(RequestBodyPlan body) => switch (body) {
  MultipartBodyPlan(:final mergeHelpers) => mergeHelpers,
  BodySelectionPlan(:final variants) => {
    for (final variant in variants)
      if (variant case MultipartBodyPlan(:final mergeHelpers)) ...mergeHelpers,
  },
  _ => const {},
};

Method _mergeListsMethod() {
  final valueType = refer('T');
  final iterableType = _iterableOf(valueType);
  return Method(
    (builder) => builder
      ..name = '_mergeMultipartLists'
      ..types.add(valueType)
      ..returns = _listOf(valueType, nullable: true)
      ..requiredParameters.add(
        _parameter('values', _listOf(_iterableOf(valueType, nullable: true))),
      )
      ..optionalParameters.add(_requiredNamed('propertyName', _string))
      ..body = Block.of([
        declareFinal('present')
            .assign(
              refer('values')
                  .property('whereType')
                  .call([], {}, [iterableType])
                  .property('toList')
                  .call([]),
            )
            .statement,
        const Code('if (present.isEmpty) return null;'),
        const Code('return [for (final value in present) ...value];'),
      ]),
  );
}

Method _mergePropertyValuesMethod() {
  final valueMap = _mapOf(_string, _propertyValue);
  return Method(
    (builder) => builder
      ..name = '_mergeMultipartPropertyValues'
      ..returns = valueMap.rebuild((builder) => builder..isNullable = true)
      ..requiredParameters.add(
        _parameter(
          'values',
          _listOf(valueMap.rebuild((builder) => builder..isNullable = true)),
        ),
      )
      ..optionalParameters.add(_requiredNamed('propertyName', _string))
      ..body = Block.of([
        declareFinal('present')
            .assign(
              refer('values')
                  .property('whereType')
                  .call([], {}, [valueMap])
                  .property('toList')
                  .call([]),
            )
            .statement,
        const Code('if (present.isEmpty) return null;'),
        declareFinal('result')
            .assign(literalMap({}, _string, _propertyValue))
            .statement,
        const Code('for (final value in present) {'),
        const Code('  for (final entry in value.entries) {'),
        const Code('    final current = result[entry.key];'),
        const Code('    if (current == null) {'),
        const Code('      result[entry.key] = entry.value;'),
        const Code('      continue;'),
        const Code('    }'),
        const Code('    result[entry.key] = '),
        refer('_mergeMultipartPropertyValue').call([
          refer('current'),
          refer('entry').property('value'),
          refer('propertyName'),
          refer('entry').property('key'),
        ]).code,
        const Code(';'),
        const Code('  }'),
        const Code('}'),
        refer('result').returned.statement,
      ]),
  );
}

Method _mergePropertyValueMethod() {
  final scalar = refer(
    'ScalarPropertyValue',
    'package:tonik_util/tonik_util.dart',
  );
  final array = refer(
    'ArrayPropertyValue',
    'package:tonik_util/tonik_util.dart',
  );
  return Method(
    (builder) => builder
      ..name = '_mergeMultipartPropertyValue'
      ..returns = _propertyValue
      ..requiredParameters.addAll([
        _parameter('current', _propertyValue),
        _parameter('incoming', _propertyValue),
        _parameter('propertyName', _string),
        _parameter('key', _string),
      ])
      ..body = Block.of([
        Block.of([
          const Code('if ('),
          refer('current').isA(scalar).code,
          const Code(' && '),
          refer('incoming').isA(scalar).code,
          const Code(' && current.value == incoming.value) {'),
          const Code('  return current;'),
          const Code('}'),
        ]),
        Block.of([
          const Code('if ('),
          refer('current').isA(array).code,
          const Code(' && '),
          refer('incoming').isA(array).code,
          const Code(') {'),
          const Code('  return '),
          _propertyValue.property('array').call([
            CodeExpression(
              Block.of([
                const Code('['),
                const Code('...current.values, '),
                const Code('...incoming.values,'),
                const Code(']'),
              ]),
            ),
          ]).code,
          const Code(';'),
          const Code('}'),
        ]),
        _encodingError(
          const Code(
            r''' 'Conflicting values for multipart property "$propertyName" at "$key".' ''',
          ),
        ),
      ]),
  );
}

Method _mergeValuesMethod() {
  final mapType = refer('Map', 'dart:core');
  final iterableType = refer('Iterable', 'dart:core');
  return Method(
    (builder) => builder
      ..name = '_mergeMultipartValues'
      ..returns = _dynamic
      ..requiredParameters.add(_parameter('values', _listOf(_dynamic)))
      ..optionalParameters.addAll([
        _requiredNamed('propertyName', _string),
        Parameter(
          (parameter) => parameter
            ..name = 'mergeObjects'
            ..named = true
            ..type = refer('bool', 'dart:core')
            ..defaultTo = literalFalse.code,
        ),
      ])
      ..body = Block.of([
        declareFinal('present')
            .assign(
              refer('values')
                  .property('where')
                  .call([_notNullClosure()])
                  .property('toList')
                  .call([]),
            )
            .statement,
        const Code('if (present.isEmpty) return null;'),
        const Code('if (mergeObjects) {'),
        declareFinal('result')
            .assign(literalMap({}, _string, _dynamic))
            .statement,
        const Code('  for (final value in present) {'),
        Block.of([
          const Code('    if (value is! '),
          mapType.code,
          const Code(') {'),
        ]),
        _encodingError(
          const Code(
            r''' 'Conflicting values for multipart property "$propertyName": expected object values.' ''',
          ),
        ),
        const Code('    }'),
        refer('_mergeMultipartMap')
            .call([refer('result'), refer('value'), refer('propertyName')])
            .statement,
        const Code('  }'),
        const Code('  return result;'),
        const Code('}'),
        Block.of([
          const Code('if ('),
          refer('present')
              .property('every')
              .call([_isTypeClosure(iterableType)])
              .code,
          const Code(') {'),
        ]),
        Block.of([
          const Code('  return [for (final value in present) ...('),
          refer('value').asA(iterableType).code,
          const Code(')];'),
        ]),
        const Code('}'),
        const Code('final first = present.first;'),
        const Code('for (final value in present.skip(1)) {'),
        const Code('  if (value != first) {'),
        _encodingError(
          const Code(
            r''' 'Conflicting values for multipart property "$propertyName".' ''',
          ),
        ),
        const Code('  }'),
        const Code('}'),
        const Code('return first;'),
      ]),
  );
}

Method _mergeMapMethod() {
  final mapType = refer('Map', 'dart:core');
  final iterableType = refer('Iterable', 'dart:core');
  final dynamicMap = _mapOf(_dynamic, _dynamic);
  return Method(
    (builder) => builder
      ..name = '_mergeMultipartMap'
      ..returns = refer('void', 'dart:core')
      ..requiredParameters.addAll([
        _parameter('target', _mapOf(_string, _dynamic)),
        _parameter('incoming', dynamicMap),
        _parameter('propertyName', _string),
      ])
      ..body = Block.of([
        const Code('for (final entry in incoming.entries) {'),
        const Code('  final key = entry.key;'),
        Block.of([
          const Code('  if (key is! '),
          _string.code,
          const Code(') {'),
        ]),
        _encodingError(
          const Code(
            r''' 'Conflicting values for multipart property "$propertyName": object keys must be strings.' ''',
          ),
        ),
        const Code('  }'),
        const Code('  if (!target.containsKey(key) || target[key] == null) {'),
        const Code('    target[key] = entry.value;'),
        const Code('    continue;'),
        const Code('  }'),
        const Code('  if (entry.value == null) continue;'),
        const Code('  final current = target[key];'),
        Block.of([
          const Code('  if ('),
          refer('current').isA(mapType).code,
          const Code(' && '),
          refer('entry').property('value').isA(mapType).code,
          const Code(') {'),
        ]),
        declareFinal('nested')
            .assign(literalMap({}, _string, _dynamic))
            .statement,
        refer('_mergeMultipartMap').call([
          refer('nested'),
          refer('current').asA(dynamicMap),
          refer('propertyName'),
        ]).statement,
        refer('_mergeMultipartMap').call([
          refer('nested'),
          refer('entry').property('value').asA(dynamicMap),
          refer('propertyName'),
        ]).statement,
        const Code('    target[key] = nested;'),
        const Code('    continue;'),
        const Code('  }'),
        Block.of([
          const Code('  if ('),
          refer('current').isA(iterableType).code,
          const Code(' && '),
          refer('entry').property('value').isA(iterableType).code,
          const Code(') {'),
        ]),
        Block.of([
          const Code('    target[key] = ['),
          const Code('...current, ...('),
          refer('entry').property('value').asA(iterableType).code,
          const Code(')];'),
        ]),
        const Code('    continue;'),
        const Code('  }'),
        const Code('  if (current != entry.value) {'),
        _encodingError(
          const Code(
            r''' 'Conflicting values for multipart property "$propertyName" at "$key".' ''',
          ),
        ),
        const Code('  }'),
        const Code('}'),
      ]),
  );
}

Parameter _parameter(String name, Reference type) => Parameter(
  (parameter) => parameter
    ..name = name
    ..type = type,
);

Parameter _requiredNamed(String name, Reference type) => Parameter(
  (parameter) => parameter
    ..name = name
    ..type = type
    ..named = true
    ..required = true,
);

TypeReference _listOf(Reference value, {bool nullable = false}) =>
    TypeReference(
      (type) => type
        ..symbol = 'List'
        ..url = 'dart:core'
        ..types.add(value)
        ..isNullable = nullable,
    );

TypeReference _iterableOf(Reference value, {bool nullable = false}) =>
    TypeReference(
      (type) => type
        ..symbol = 'Iterable'
        ..url = 'dart:core'
        ..types.add(value)
        ..isNullable = nullable,
    );

TypeReference _mapOf(Reference key, Reference value) => TypeReference(
  (type) => type
    ..symbol = 'Map'
    ..url = 'dart:core'
    ..types.addAll([key, value]),
);

Expression _notNullClosure() => Method(
  (method) => method
    ..requiredParameters.add(
      Parameter((parameter) => parameter..name = 'value'),
    )
    ..lambda = true
    ..body = refer('value').notEqualTo(literalNull).code,
).closure;

Expression _isTypeClosure(Reference type) => Method(
  (method) => method
    ..requiredParameters.add(
      Parameter((parameter) => parameter..name = 'value'),
    )
    ..lambda = true
    ..body = refer('value').isA(type).code,
).closure;

Code _encodingError(Code message) => refer(
  'EncodingException',
  'package:tonik_util/tonik_util.dart',
).call([CodeExpression(message)]).thrown.statement;
