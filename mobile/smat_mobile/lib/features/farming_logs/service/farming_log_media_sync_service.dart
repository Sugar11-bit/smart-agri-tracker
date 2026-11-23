import '../data/farming_log_media_local_repository.dart';
import '../data/farming_log_media_remote_repository.dart';

class MediaSyncResult {
  final int photosSynced;
  final int locationsSynced;
  final int failed;
  final bool loginRequired;

  const MediaSyncResult({
    required this.photosSynced,
    required this.locationsSynced,
    required this.failed,
    required this.loginRequired,
  });
}

class FarmingLogMediaSyncService {
  final FarmingLogMediaLocalRepository local;
  final FarmingLogMediaRemoteRepository remote;

  bool _running = false;

  FarmingLogMediaSyncService({required this.local, required this.remote});

  Future<MediaSyncResult> sync({
    required int userId,
    required String token,
  }) async {
    if (_running) {
      throw StateError('Media Sync đang chạy');
    }

    _running = true;

    var photosSynced = 0;
    var locationsSynced = 0;
    var failed = 0;
    var loginRequired = false;

    try {
      await local.recoverInterruptedSync(userId);

      // PHẦN 1: Đồng bộ ảnh.
      final photos = await local.pendingPhotos(userId);

      for (final photo in photos) {
        final photoId = photo['local_photo_id'] as String;
        final path = photo['local_path'] as String;
        final serverLogId = photo['server_id'] as int;

        final claimed = await local.setPhotoStatus(
          userId: userId,
          photoId: photoId,
          from: 'PENDING',
          to: 'SYNCING',
        );

        if (claimed != 1) continue;

        try {
          final ack = await remote.uploadPhoto(
            serverLogId: serverLogId,
            clientPhotoId: photoId,
            localPath: path,
            token: token,
          );

          final updated = await local.setPhotoStatus(
            userId: userId,
            photoId: photoId,
            from: 'SYNCING',
            to: 'SYNCED',
            serverPhotoId: ack.id,
          );

          if (updated != 1) {
            throw StateError('Không cập nhật được trạng thái ảnh $photoId');
          }

          photosSynced++;
        } on MediaSyncException catch (error) {
          if (error.kind == MediaErrorKind.temporary ||
              error.kind == MediaErrorKind.authentication) {
            await local.setPhotoStatus(
              userId: userId,
              photoId: photoId,
              from: 'SYNCING',
              to: 'PENDING',
              error: error.message,
            );

            if (error.kind == MediaErrorKind.authentication) {
              loginRequired = true;
            }

            // Mạng/server lỗi thì không tiếp tục
            // gửi hàng loạt trong cùng lượt.
            return MediaSyncResult(
              photosSynced: photosSynced,
              locationsSynced: locationsSynced,
              failed: failed,
              loginRequired: loginRequired,
            );
          }

          await local.setPhotoStatus(
            userId: userId,
            photoId: photoId,
            from: 'SYNCING',
            to: 'FAILED',
            error: error.message,
          );

          failed++;
        }
      }

      // PHẦN 2: Đồng bộ GPS.
      final locations = await local.pendingLocations(userId);

      for (final location in locations) {
        final localId = location['farming_log_local_id'] as String;

        final serverLogId = location['server_id'] as int;

        final claimed = await local.setLocationStatus(
          userId: userId,
          logLocalId: localId,
          from: 'PENDING',
          to: 'SYNCING',
        );

        if (claimed != 1) continue;

        try {
          await remote.uploadLocation(
            serverLogId: serverLogId,
            latitude: (location['latitude'] as num).toDouble(),
            longitude: (location['longitude'] as num).toDouble(),
            accuracyMeters: (location['accuracy_meters'] as num).toDouble(),
            capturedAt: location['captured_at'] as String,
            token: token,
          );

          final updated = await local.setLocationStatus(
            userId: userId,
            logLocalId: localId,
            from: 'SYNCING',
            to: 'SYNCED',
          );

          if (updated != 1) {
            throw StateError('Không cập nhật được GPS: $localId');
          }

          locationsSynced++;
        } on MediaSyncException catch (error) {
          if (error.kind == MediaErrorKind.temporary ||
              error.kind == MediaErrorKind.authentication) {
            await local.setLocationStatus(
              userId: userId,
              logLocalId: localId,
              from: 'SYNCING',
              to: 'PENDING',
              error: error.message,
            );

            if (error.kind == MediaErrorKind.authentication) {
              loginRequired = true;
            }

            return MediaSyncResult(
              photosSynced: photosSynced,
              locationsSynced: locationsSynced,
              failed: failed,
              loginRequired: loginRequired,
            );
          }

          await local.setLocationStatus(
            userId: userId,
            logLocalId: localId,
            from: 'SYNCING',
            to: 'FAILED',
            error: error.message,
          );

          failed++;
        }
      }

      return MediaSyncResult(
        photosSynced: photosSynced,
        locationsSynced: locationsSynced,
        failed: failed,
        loginRequired: loginRequired,
      );
    } finally {
      _running = false;
    }
  }
}
