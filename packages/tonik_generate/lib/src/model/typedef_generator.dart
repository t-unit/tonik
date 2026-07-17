import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/file_name.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart typedef files from
/// alias and list model definitions.
@immutable
class TypedefGenerator {
  const TypedefGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

  ({String code, String filename}) generateAlias(AliasModel model) =>
      _generateFile(generateAliasTypedef(model));

  ({String code, String filename}) generateList(ListModel model) =>
      _generateFile(generateListTypedef(model));

  ({String code, String filename}) generateMap(MapModel model) =>
      _generateFile(generateMapTypedef(model));

  @visibleForTesting
  TypeDef generateAliasTypedef(AliasModel model) {
    final isNullable = model.isNullable;

    final baseType = typeReference(
      model.model,
      nameManager,
      package,
      isNullableOverride: isNullable,
      useImmutableCollections: useImmutableCollections,
    );

    return TypeDef(
      (b) {
        b
          ..name = nameManager.modelName(model)
          ..definition = baseType
          ..docs.addAll(
            formatDocsWithExamples(model.description, model.examples),
          );

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This typedef is deprecated.'),
            ]),
          );
        }
      },
    );
  }

  @visibleForTesting
  TypeDef generateListTypedef(ListModel model) {
    final isNullable = model.isNullable;

    const ficUrl =
        'package:fast_immutable_collections/fast_immutable_collections.dart';
    final baseType = TypeReference(
      (b) => b
        ..symbol = useImmutableCollections ? 'IList' : 'List'
        ..url = useImmutableCollections ? ficUrl : 'dart:core'
        ..types.add(
          _safeContentTypeReference(model, model.content),
        )
        ..isNullable = isNullable,
    );

    return TypeDef(
      (b) => b
        ..name = nameManager.modelName(model)
        ..definition = baseType
        ..docs.addAll(formatDocsWithExamples(null, model.examples)),
    );
  }

  @visibleForTesting
  TypeDef generateMapTypedef(MapModel model) {
    final isNullable = model.isNullable;

    const ficUrl =
        'package:fast_immutable_collections/fast_immutable_collections.dart';
    final baseType = TypeReference(
      (b) => b
        ..symbol = useImmutableCollections ? 'IMap' : 'Map'
        ..url = useImmutableCollections ? ficUrl : 'dart:core'
        ..types.addAll([
          refer('String', 'dart:core'),
          _safeContentTypeReference(model, model.valueModel),
        ])
        ..isNullable = isNullable,
    );

    return TypeDef(
      (b) => b
        ..name = nameManager.modelName(model)
        ..definition = baseType
        ..docs.addAll(formatDocsWithExamples(null, model.examples)),
    );
  }

  /// Returns a [TypeReference] for the content/value model of a typedef'd
  /// collection. When the content reaches back to a recursive named typedef
  /// (directly or through any chain), Dart forbids the self-reference; in
  /// that case we erase to `Object?` for the typedef RHS only — runtime
  /// recursion is broken by the inline `_decode<Type>` / `_encode<Type>`
  /// helpers emitted at every use site.
  TypeReference _safeContentTypeReference(Model owner, Model content) {
    if (_reachesRecursiveTypedef(content, owner)) {
      return TypeReference(
        (b) => b
          ..symbol = 'Object?'
          ..url = 'dart:core',
      );
    }
    final isElementNullable = switch (owner) {
      ListModel(:final isContentNullable) => isContentNullable,
      MapModel(:final isValueNullable) => isValueNullable,
      _ => false,
    };
    return typeReference(
      content,
      nameManager,
      package,
      isNullableOverride: isElementNullable,
      useImmutableCollections: useImmutableCollections,
    );
  }

  bool _reachesRecursiveTypedef(Model start, Model self) {
    final visited = <Model>{};

    bool walk(Model m) {
      if (identical(m, self)) return true;
      if (!visited.add(m)) return false;
      if (m is AliasModel) return walk(m.model);
      if (m is MapModel) {
        if (m.name != null && isRecursive(m)) return true;
        return walk(m.valueModel);
      }
      if (m is ListModel) {
        if (m.name != null && isRecursive(m)) return true;
        return walk(m.content);
      }
      return false;
    }

    return walk(start);
  }

  ({String code, String filename}) _generateFile(TypeDef typedef) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final fileName = fileNameForClass(typedef.name);
    final library = Library((b) => b.body.add(typedef));

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: fileName);
  }
}
