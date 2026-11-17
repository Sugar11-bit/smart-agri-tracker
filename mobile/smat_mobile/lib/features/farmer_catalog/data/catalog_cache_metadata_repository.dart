import 'package:sqflite/sqflite.dart';

import '../../plots/data/plot_cache.dart';

class CatalogCacheInfo {
  final DateTime fetchedAt;
  final int itemCount;

  const CatalogCacheInfo({required this.fetchedAt, required this.itemCount});

  bool isStale(Duration maxAge) {
    final age = DateTime.now().toUtc().difference(fetchedAt.toUtc());

    // Đồng hồ thiết bị có thể bị chỉnh sai.
    if (age.isNegative) return true;

    return age > maxAge;
  }
}

class CatalogCacheMetadataRepository {
  final PlotCache cache;

  CatalogCacheMetadataRepository(this.cache);

  // Dùng bên trong transaction hiện có.
  Future<void> saveInTransaction({
    required Transaction txn,
    required int userId,
    required int organizationId,
    required String scopeType,
    required int parentId,
    required int itemCount,
  }) async {
    if (scopeType != 'PLANTINGS' && scopeType != 'CYCLES') {
      throw ArgumentError('Invalid cache scope');
    }

    await txn.insert('catalog_cache_metadata', {
      'user_id': userId,
      'organization_id': organizationId,
      'scope_type': scopeType,
      'parent_id': parentId,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
      'item_count': itemCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CatalogCacheInfo?> read({
    required int userId,
    required int organizationId,
    required String scopeType,
    required int parentId,
  }) async {
    final db = await cache.database;

    final rows = await db.query(
      'catalog_cache_metadata',
      where: '''
        user_id = ?
        AND organization_id = ?
        AND scope_type = ?
        AND parent_id = ?
      ''',
      whereArgs: [userId, organizationId, scopeType, parentId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;

    return CatalogCacheInfo(
      fetchedAt: DateTime.parse(row['fetched_at'] as String),
      itemCount: row['item_count'] as int,
    );
  }
}
