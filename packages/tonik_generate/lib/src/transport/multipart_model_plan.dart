import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A logical wire part and the regular-model fields which contribute to it.
class MultipartPropertyPlan {
  MultipartPropertyPlan(this.property, this.encoding, this.sources);

  final Property property;
  final PartEncoding encoding;
  final List<MultipartPropertySource> sources;
  String get name => property.name;
  Model get model => property.model;
  bool get isRequired =>
      sources.any((s) => s.property.isRequired && !s.optionalParent);
  bool get isNullable => !sources.any(
    (s) =>
        s.property.isRequired &&
        !s.property.isNullable &&
        !multipartValueIsNullable(s.property.model) &&
        !s.optionalParent,
  );
}

typedef MultipartPropertySource = ({
  Property property,
  Expression value,
  bool optionalParent,
});

List<({String normalizedName, MultipartPropertyPlan part})>
planMultipartProperties(
  MultipartRequestContent content, {
  String bodyAccessor = 'body',
  NameManager? nameManager,
  String package = 'api',
  bool useImmutableCollections = false,
}) {
  final manager =
      nameManager ??
      NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
  final parts = <String, MultipartPropertyPlan>{};
  final visiting = Set<Model>.identity();
  void visit(
    Model model,
    Expression value, {
    required bool optionalParent,
    bool isRoot = false,
  }) {
    if (model.hasPrunedCompositionCycle || !visiting.add(model)) {
      throw StateError('Cyclic multipart body model at ${model.context}.');
    }
    switch (model) {
      case AliasModel():
        visit(
          model.model,
          value,
          optionalParent: optionalParent,
          isRoot: isRoot,
        );
      case ClassModel():
        if (!model.isReadOnly) {
          for (final entry in normalizeProperties(model.properties)) {
            final property = entry.property;
            if (property.isReadOnly) continue;
            final source = (
              property: property,
              value: optionalParent
                  ? value.nullSafeProperty(entry.normalizedName)
                  : value.property(entry.normalizedName),
              optionalParent: optionalParent,
            );
            final existing = parts[property.name];
            if (existing == null) {
              parts[property.name] = MultipartPropertyPlan(
                property,
                resolveMultipartEncoding(
                  content.encoding[property.name],
                  property.model,
                ),
                [source],
              );
            } else {
              for (final previous in existing.sources) {
                if (!_compatible(previous.property.model, property.model, {})) {
                  throw StateError(
                    'Incompatible multipart property "${property.name}" '
                    'definitions.',
                  );
                }
              }
              existing.sources.add(source);
            }
          }
        }
      case AllOfModel():
        if (model.isReadOnly) {
          if (isRoot) {
            throw StateError(
              'Cannot encode readOnly allOf multipart body '
              'at ${model.context}.',
            );
          }
          break;
        }
        final members = ensureUniqueness(
          model.models
              .map(
                (member) => (
                  normalizedName: normalizeSingle(
                    typeReference(
                      member,
                      manager,
                      package,
                      useImmutableCollections: useImmutableCollections,
                    ).symbol,
                    preserveNumbers: true,
                  ),
                  originalValue: member,
                ),
              )
              .toList(),
        );
        for (final member in members) {
          final nullable =
              optionalParent || multipartValueIsNullable(member.originalValue);
          visit(
            member.originalValue,
            optionalParent
                ? value.nullSafeProperty(member.normalizedName)
                : value.property(member.normalizedName),
            optionalParent: nullable,
          );
        }
      default:
        throw StateError(
          'Unsupported multipart body model ${model.runtimeType} '
          'at ${model.context}; expected a class, alias, or allOf of classes.',
        );
    }
    visiting.remove(model);
  }

  final root = refer(bodyAccessor);
  visit(
    content.model,
    multipartValueIsNullable(content.model) ? root.nullChecked : root,
    optionalParent: false,
    isRoot: true,
  );
  return ensureUniqueness(
        parts.values
            .map(
              (part) => (
                normalizedName: normalizeSingle(
                  part.property.nameOverride ?? part.name,
                  preserveNumbers: true,
                ),
                originalValue: part,
              ),
            )
            .toList(),
        defaultPrefix: defaultFieldPrefix,
      )
      .map(
        (entry) => (
          normalizedName: entry.normalizedName,
          part: entry.originalValue,
        ),
      )
      .toList();
}

PartEncoding resolveMultipartEncoding(PartEncoding? encoding, Model model) {
  if (encoding != null && encoding.isStyleBased) {
    return PartEncoding(
      contentType: null,
      rawContentType: null,
      textEncoding: encoding.textEncoding,
      headers: encoding.headers,
      style: encoding.style,
      explode: encoding.explode,
      allowReserved: encoding.allowReserved,
    );
  }
  final contentType =
      encoding?.contentType ??
      _defaultContentType(model, Set<Model>.identity());
  final raw =
      encoding?.rawContentType ??
      switch (contentType) {
        ContentType.json => 'application/json',
        ContentType.bytes => 'application/octet-stream',
        _ => 'text/plain',
      };
  return PartEncoding(
    contentType: contentType,
    rawContentType: raw,
    wireContentType: encoding?.wireContentType ?? raw,
    textEncoding: encoding?.textEncoding ?? TextEncoding.utf8,
    headers: encoding?.headers,
    style: null,
    explode: null,
    allowReserved: null,
  );
}

ContentType _defaultContentType(Model model, Set<Model> visiting) {
  if (!visiting.add(model)) return ContentType.json;
  return switch (model) {
    AliasModel() => _defaultContentType(model.model, visiting),
    ListModel() => _defaultContentType(model.content, visiting),
    BinaryModel() || Base64Model() => ContentType.bytes,
    ClassModel() ||
    CompositeModel() ||
    MapModel() ||
    AnyModel() => ContentType.json,
    _ => ContentType.text,
  };
}

bool _compatible(Model first, Model second, Set<(Model, Model)> visiting) {
  if (identical(first, second)) return true;
  if (!visiting.add((first, second))) return true;
  if (first is AliasModel) return _compatible(first.model, second, visiting);
  if (second is AliasModel) return _compatible(first, second.model, visiting);
  if (first is AnyModel || second is AnyModel) return true;
  if (first is ListModel && second is ListModel) {
    return _compatible(first.content, second.content, visiting);
  }
  if (first is MapModel && second is MapModel) {
    return _compatible(first.valueModel, second.valueModel, visiting);
  }
  if (first is AllOfModel) {
    return first.models.every((m) => _compatible(m, second, visiting));
  }
  if (second is AllOfModel) {
    return second.models.every((m) => _compatible(first, m, visiting));
  }
  if (first is ClassModel && second is ClassModel) {
    for (final a in first.properties) {
      for (final b in second.properties.where((p) => p.name == a.name)) {
        if (!_compatible(a.model, b.model, visiting)) return false;
      }
    }
    return true;
  }
  if (first is ClassModel && second is MapModel) {
    return first.properties.every(
      (p) => _compatible(p.model, second.valueModel, visiting),
    );
  }
  if (first is MapModel && second is ClassModel) {
    return _compatible(second, first, visiting);
  }
  if (first is EnumModel && second is EnumModel) {
    return first.values.any(
      (a) => second.values.any((b) => a.value == b.value),
    );
  }
  return first.runtimeType == second.runtimeType && first is PrimitiveModel;
}

/// Alias cycles are diagnosed by the root walk or value serializer.
bool multipartValueIsNullable(Model model) {
  final visited = Set<Model>.identity();
  var current = model;
  while (current is AliasModel) {
    if (!visited.add(current)) return false;
    if (current.isNullable) return true;
    current = current.model;
  }
  return current.isEffectivelyNullable;
}
