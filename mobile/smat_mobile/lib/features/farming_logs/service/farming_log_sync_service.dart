//SyncService là người chuyển từng trang nhật ký từ điện thoại lên máy chủ
import '../data/farming_log_local_repository.dart';
import '../data/farming_log_remote_repository.dart';

class SyncSummary {
  final int synced;
  final int pending;
  final int failed;
  final bool loginRequired;

  const SyncSummary({
    required this.synced,
    required this.pending,
    required this.failed,
    required this.loginRequired,
  });
}

class FarmingLogSyncService {
  final FarmingLogLocalRepository local;
  final FarmingLogRemoteRepository remote;

  bool _running = false;

  FarmingLogSyncService({required this.local, required this.remote});

  Future<SyncSummary> syncPending({
    required int userId,
    required Future<String?> Function() readAccessToken,
  }) async {
    // Không chạy đồng thời hai lượt sync
    // trên cùng một service instance.
    if (_running) {
      throw StateError('Đang đồng bộ, vui lòng thử lại');
    }

    _running = true;

    var synced = 0;
    var pending = 0;
    var failed = 0;
    var loginRequired = false;

    try {
      // Phục hồi các request bị gián đoạn
      // từ lần chạy ứng dụng trước.
      await local.recoverInterruptedSync(userId);

      final logs = await local.getPendingLogs(userId);

      // Đọc JWT cho đúng phiên hiện tại.
      final token = await readAccessToken();

      if (token == null || token.isEmpty) {
        return SyncSummary(
          synced: 0,
          pending: logs.length,
          failed: 0,
          loginRequired: true,
        );
      }

      for (final log in logs) {
        final claimed = await local.markSyncing(userId, log.localId);

        if (!claimed) continue;

        try {
          final ack = await remote.upload(log: log, token: token);

          final updated = await local.markSynced(
            userId: userId,
            localId: log.localId,
            serverId: ack.serverId,
            serverReceivedAt: ack.serverReceivedAt,
          );

          if (!updated) {
            throw StateError('Không cập nhật được SQLite: ${log.localId}');
          }

          synced++;
        } on SyncRemoteException catch (error) {
          if (error.type == SyncErrorType.temporary) {
            await local.markPending(
              userId: userId,
              localId: log.localId,
              error: error.message,
            );

            pending++;

            // Dừng để tránh gửi liên tục
            // khi server hoặc mạng đang lỗi.
            break;
          }

          if (error.type == SyncErrorType.authentication) {
            await local.markPending(
              userId: userId,
              localId: log.localId,
              error: error.message,
            );

            pending++;
            loginRequired = true;
            break;
          }

          await local.markFailed(
            userId: userId,
            localId: log.localId,
            error: error.message,
          );

          failed++;
        }
      }

      return SyncSummary(
        synced: synced,
        pending: pending,
        failed: failed,
        loginRequired: loginRequired,
      );
    } finally {
      _running = false;
    }
  }
}
