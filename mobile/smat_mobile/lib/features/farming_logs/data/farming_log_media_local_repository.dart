import '../../plots/data/plot_cache.dart';

class FarmingLogMediaLocalRepository {
  final PlotCache cache;

  FarmingLogMediaLocalRepository(this.cache);

  Future<List<Map<String, Object?>>> pendingPhotos(int userId) async {
    final db = await cache.database;

    return db.rawQuery(
      '''
      SELECT
        p.local_photo_id,
        p.farming_log_local_id,
        p.local_path,
        l.server_id
      FROM farming_log_photos p
      JOIN farming_logs l
        ON l.local_id = p.farming_log_local_id
       AND l.user_id = p.user_id
      WHERE p.user_id = ?
        AND p.sync_status = 'PENDING'
        AND l.sync_status = 'SYNCED'
        AND l.server_id IS NOT NULL
      ORDER BY p.created_at ASC
    ''',
      [userId],
    );
  }

  Future<List<Map<String, Object?>>> pendingLocations(int userId) async {
    final db = await cache.database;

    return db.rawQuery(
      '''
      SELECT
        g.farming_log_local_id,
        g.latitude,
        g.longitude,
        g.accuracy_meters,
        g.captured_at,
        l.server_id
      FROM farming_log_locations g
      JOIN farming_logs l
        ON l.local_id = g.farming_log_local_id
       AND l.user_id = g.user_id
      WHERE g.user_id = ?
        AND g.sync_status = 'PENDING'
        AND l.sync_status = 'SYNCED'
        AND l.server_id IS NOT NULL
      ORDER BY g.captured_at ASC
    ''',
      [userId],
    );
  }

  Future<int> setPhotoStatus({
    required int userId,
    required String photoId,
    required String from,
    required String to,
    int? serverPhotoId,
    String? error,
  }) async {
    final db = await cache.database;

    return db.update(
      'farming_log_photos',
      {
        'sync_status': to,
        'last_error': error,
        'sync_status': to,
        'last_error': error,
        if (serverPhotoId != null) 'server_photo_id': serverPhotoId,
      },
      where: '''
        user_id = ?
        AND local_photo_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, photoId, from],
    );
  }

  Future<int> setLocationStatus({
    required int userId,
    required String logLocalId,
    required String from,
    required String to,
    String? error,
  }) async {
    final db = await cache.database;

    return db.update(
      'farming_log_locations',
      {'sync_status': to, 'last_error': error},
      where: '''
        user_id = ?
        AND farming_log_local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, logLocalId, from],
    );
  }

  Future<void> recoverInterruptedSync(int userId) async {
    final db = await cache.database;

    await db.transaction((txn) async {
      await txn.update(
        'farming_log_photos',
        {'sync_status': 'PENDING'},
        where: "user_id = ? AND sync_status = 'SYNCING'",
        whereArgs: [userId],
      );

      await txn.update(
        'farming_log_locations',
        {'sync_status': 'PENDING'},
        where: "user_id = ? AND sync_status = 'SYNCING'",
        whereArgs: [userId],
      );
    });
  }
}
