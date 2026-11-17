class FarmingLogPhotoModel {
  final String localPhotoId;
  final String farmingLogLocalId;
  final int userId;
  final String localPath;
  final String createdAt;
  final String syncStatus;
  final int? serverPhotoId;
  final String? lastError;

  const FarmingLogPhotoModel({
    required this.localPhotoId,
    required this.farmingLogLocalId,
    required this.userId,
    required this.localPath,
    required this.createdAt,
    this.syncStatus = 'PENDING',
    this.serverPhotoId,
    this.lastError,
  });

  Map<String, Object?> toDatabase() {
    return {
      'local_photo_id': localPhotoId,
      'farming_log_local_id': farmingLogLocalId,
      'user_id': userId,
      'local_path': localPath,
      'created_at': createdAt,
      'sync_status': syncStatus,
      'server_photo_id': serverPhotoId,
      'last_error': lastError,
    };
  }

  factory FarmingLogPhotoModel.fromDatabase(Map<String, Object?> row) {
    return FarmingLogPhotoModel(
      localPhotoId: row['local_photo_id'] as String,
      farmingLogLocalId: row['farming_log_local_id'] as String,
      userId: row['user_id'] as int,
      localPath: row['local_path'] as String,
      createdAt: row['created_at'] as String,
      syncStatus: row['sync_status'] as String,
      serverPhotoId: row['server_photo_id'] as int?,
      lastError: row['last_error'] as String?,
    );
  }
}
