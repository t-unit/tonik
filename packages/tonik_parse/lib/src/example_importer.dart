import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

class ExampleImporter {
  ExampleImporter({required this.openApiObject});

  final OpenApiObject openApiObject;
  final log = Logger('ExampleImporter');

  List<core.Example> fromSchema(Schema? schema) {
    if (schema == null) return const [];

    final result = <core.Example>[];
    if (schema.example != null) {
      result.add(
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: schema.example,
        ),
      );
    }
    if (schema.examples != null) {
      for (final value in schema.examples!) {
        result.add(
          core.Example(
            name: null,
            summary: null,
            description: null,
            value: value,
          ),
        );
      }
    }
    return result;
  }

  List<core.Example> fromMediaType(MediaType media) {
    final mediaLevel = _mergeMediaLevel(
      example: media.example,
      examples: media.examples,
    );
    if (mediaLevel.isNotEmpty) return mediaLevel;
    return fromSchema(media.schema);
  }

  List<core.Example> fromParameter(Parameter parameter) {
    final paramLevel = _mergeMediaLevel(
      example: parameter.example,
      examples: parameter.examples,
    );
    if (paramLevel.isNotEmpty) return paramLevel;
    return fromSchema(parameter.schema);
  }

  List<core.Example> fromHeader(Header header) {
    final headerLevel = _mergeMediaLevel(
      example: header.example,
      examples: header.examples,
    );
    if (headerLevel.isNotEmpty) return headerLevel;
    return fromSchema(header.schema);
  }

  List<core.Example> _mergeMediaLevel({
    required Object? example,
    required Map<String, ReferenceWrapper<Example>>? examples,
  }) {
    final result = <core.Example>[];
    if (example != null) {
      result.add(
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: example,
        ),
      );
    }
    if (examples != null) {
      for (final entry in examples.entries) {
        final wrapper = entry.value;
        // OAS 3.1+: a Reference's summary/description override the target's.
        final summaryOverride = wrapper is Reference<Example>
            ? wrapper.summary
            : null;
        final descriptionOverride = wrapper is Reference<Example>
            ? wrapper.description
            : null;
        final resolved = _resolveExample(wrapper, <String>[]);
        final converted = _convert(
          name: entry.key,
          example: resolved,
          summaryOverride: summaryOverride,
          descriptionOverride: descriptionOverride,
        );
        if (converted != null) {
          result.add(converted);
        }
      }
    }
    return result;
  }

  Example _resolveExample(
    ReferenceWrapper<Example> wrapper,
    List<String> chain,
  ) {
    switch (wrapper) {
      case Reference<Example>():
        if (!wrapper.ref.startsWith('#/components/examples/')) {
          throw UnimplementedError(
            'Only local example references are supported, '
            'found ${wrapper.ref}',
          );
        }

        if (chain.contains(wrapper.ref)) {
          final cycleChain = [...chain, wrapper.ref];
          throw ArgumentError(
            'Cyclic example reference: ${cycleChain.join(" -> ")}',
          );
        }

        final refName = wrapper.ref.split('/').last;
        final refExample = openApiObject.components?.examples?[refName];
        if (refExample == null) {
          throw ArgumentError('Example $refName not found');
        }
        return _resolveExample(refExample, [...chain, wrapper.ref]);

      case InlinedObject<Example>():
        return wrapper.object;
    }
  }

  core.Example? _convert({
    required String name,
    required Example example,
    String? summaryOverride,
    String? descriptionOverride,
  }) {
    final hasData = example.hasExplicitDataValue || example.hasExplicitValue;
    final effectiveValue = example.hasExplicitDataValue
        ? example.dataValue
        : example.value;

    // externalValue and serializedValue are non-native forms tonik can't
    // consume; drop silently when one of them is the only payload.
    if (!hasData &&
        (example.externalValue != null || example.serializedValue != null)) {
      return null;
    }

    if (!hasData &&
        example.externalValue == null &&
        example.serializedValue == null) {
      log.warning(
        'Skipping Example "$name" - none of `value`, `dataValue`, '
        '`serializedValue`, or `externalValue` is set.',
      );
      return null;
    }

    return core.Example(
      name: name,
      summary: summaryOverride ?? example.summary,
      description: descriptionOverride ?? example.description,
      value: effectiveValue,
    );
  }
}
