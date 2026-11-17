import 'package:sqflite/sqflite.dart';

import '../../plots/data/plot_cache.dart';
import 'farming_log_model.dart';
import 'farming_log_photo_model.dart';

import 'farming_log_location_model.dart';

class FarmingLogLocalRepository {
  final PlotCache cache;

  FarmingLogLocalRepository(this.cache);

  // Lưu nhật ký mới
  Future<void> createLog(FarmingLogModel log) async {
    final db = await cache.database;

    await db.insert(
      'farming_logs',
      log.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Đọc nhật ký của Farmer đang đăng nhập
  Future<List<FarmingLogModel>> getLogsByUser(int userId) async {
    final db = await cache.database;

    final rows = await db.query(
      'farming_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'client_created_at DESC',
    );

    return rows.map(FarmingLogModel.fromDatabase).toList();
  }

  // Lấy nhật ký đang chờ đồng bộ
  Future<List<FarmingLogModel>> getPendingLogs(int userId) async {
    final db = await cache.database;

    final rows = await db.query(
      'farming_logs',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, 'PENDING'],
      orderBy: 'client_created_at ASC',
    );

    return rows.map(FarmingLogModel.fromDatabase).toList();
  }

  // Chuyển PENDING sang SYNCING
  Future<bool> markSyncing(int userId, String localId) async {
    final db = await cache.database;

    final count = await db.update(
      'farming_logs',
      {'sync_status': 'SYNCING', 'last_error': null},
      where: '''
        user_id = ?
        AND local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, localId, 'PENDING'],
    );

    return count == 1;
  }

  // Backend xác nhận đồng bộ thành công
  Future<bool> markSynced({
    required int userId,
    required String localId,
    required int serverId,
    required String serverReceivedAt,
  }) async {
    final db = await cache.database;

    final count = await db.update(
      'farming_logs',
      {
        'sync_status': 'SYNCED',
        'server_id': serverId,
        'server_received_at': serverReceivedAt,
        'last_error': null,
      },
      where: '''
        user_id = ?
        AND local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, localId, 'SYNCING'],
    );

    return count == 1;
  }

  // Ghi nhận lỗi đồng bộ
  Future<bool> markFailed({
    required int userId,
    required String localId,
    required String error,
  }) async {
    final db = await cache.database;

    final count = await db.update(
      'farming_logs',
      {'sync_status': 'FAILED', 'last_error': error},
      where: '''
        user_id = ?
        AND local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, localId, 'SYNCING'],
    );

    return count == 1;
  }

  // Phục hồi khi app bị đóng trong lúc đồng bộ
  Future<int> recoverInterruptedSync(int userId) async {
    final db = await cache.database;

    return db.update(
      'farming_logs',
      {'sync_status': 'PENDING'},
      where: '''
        user_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, 'SYNCING'],
    );
  }

  //Nếu đang gửi mà mạng bị ngắt thì sẽ chuyển thành PENDING để gửi lại lần sau. KHông xóa nhật ký không tạo UUID mới
  Future<bool> markPending({
    required int userId,
    required String localId,
    String? error,
  }) async {
    final db = await cache.database;

    final count = await db.update(
      'farming_logs',
      {'sync_status': 'PENDING', 'last_error': error},
      where: '''
        user_id = ?
        AND local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, localId, 'SYNCING'],
    );

    return count == 1;
  }

  // Thử lại đồng bộ khi đã thất bại
  Future<bool> retryFailed(int userId, String localId) async {
    final db = await cache.database;

    final count = await db.update(
      'farming_logs',
      {'sync_status': 'PENDING', 'last_error': null},
      where: '''
        user_id = ?
        AND local_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [userId, localId, 'FAILED'],
    );

    return count == 1;
  }

  Future<void> createLogWithPhotos({
    required FarmingLogModel log,
    required List<FarmingLogPhotoModel> photos,
    FarmingLogLocationModel? location,
  }) async {
    final db = await cache.database;

    // Kiểm tra ảnh thuộc đúng nhật ký.
    for (final photo in photos) {
      if (photo.farmingLogLocalId != log.localId ||
          photo.userId != log.userId) {
        throw ArgumentError('Ảnh không thuộc Farming Log hiện tại');
      }
    }

    // Kiểm tra GPS thuộc đúng nhật ký.
    if (location != null) {
      if (location.farmingLogLocalId != log.localId ||
          location.userId != log.userId) {
        throw ArgumentError('GPS không thuộc Farming Log hiện tại');
      }
    }

    await db.transaction((txn) async {
      // 1. Lưu nhật ký.
      await txn.insert(
        'farming_logs',
        log.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // 2. Lưu thông tin ảnh.
      for (final photo in photos) {
        await txn.insert(
          'farming_log_photos',
          photo.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      // 3. Chỉ lưu GPS nếu Farmer đã lấy được.
      if (location != null) {
        await txn.insert(
          'farming_log_locations',
          location.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  //Hàm này sẽ được sử dụng khi chúng ta xây màn hình xem chi tiết nhật ký và khi chuẩn bị gửi GPS lên Backend.
  Future<FarmingLogLocationModel?> getLocationByLog({
    required int userId,
    required String farmingLogLocalId,
  }) async {
    final db = await cache.database;

    final rows = await db.query(
      'farming_log_locations',
      where: '''
      user_id = ?
      AND farming_log_local_id = ?
    ''',
      whereArgs: [userId, farmingLogLocalId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return FarmingLogLocationModel.fromDatabase(rows.first);
  }

  // Lấy danh sách ảnh của nhật ký
  Future<List<FarmingLogPhotoModel>> getPhotosByLog({
    required int userId,
    required String farmingLogLocalId,
  }) async {
    final db = await cache.database;

    final rows = await db.query(
      'farming_log_photos',
      where: '''
      user_id = ?
      AND farming_log_local_id = ?
    ''',
      whereArgs: [userId, farmingLogLocalId],
      orderBy: 'created_at ASC',
    );

    return rows.map(FarmingLogPhotoModel.fromDatabase).toList();
  }
}
