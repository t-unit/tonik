// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:core' as _i2;

import 'package:immutable_collections_api/immutable_collections_api.dart'
    as _i1;
import 'package:tonik_util/tonik_util.dart' as _i3;

/// Operations for items with collection fields
class ItemsApi {
  ItemsApi(_i1.Server server)
    : _getItem = _i1.GetItem(server.dio),
      _createItem = _i1.CreateItem(server.dio),
      _createNested = _i1.CreateNested(server.dio);

  final _i1.GetItem _getItem;

  final _i1.CreateItem _createItem;

  final _i1.CreateNested _createNested;

  /// Get a single item by ID
  _i2.Future<_i3.TonikResult<_i1.GetItemResponse>> getItem({
    required _i2.int id,
  }) async => _getItem(id: id);

  /// Create a new item
  _i2.Future<_i3.TonikResult<_i1.Item>> createItem({
    required _i1.Item body,
  }) async => _createItem(body: body);

  /// Create a nested list structure
  _i2.Future<_i3.TonikResult<_i1.NestedList>> createNested({
    required _i1.NestedList body,
  }) async => _createNested(body: body);
}
