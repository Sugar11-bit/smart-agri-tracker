import 'package:flutter/material.dart';

import '../../../core/security/token_storage.dart';
import '../data/farming_log_local_repository.dart';
import '../data/farming_log_location_model.dart';
import '../data/farming_log_model.dart';

// Thêm nút đồng bộ dữ liệu với Backend (nếu có kết nối Internet).
import "../data/farming_log_remote_repository.dart";
import '../service/farming_log_sync_service.dart';

// Thêm nút đồng bộ dữ liệu với Backend (nếu có kết nối Internet).
import '../../farmer_catalog/data/farmer_catalog_repository.dart';
import 'farming_log_selection_screen.dart';

class FarmingLogListScreen extends StatefulWidget {
  final Session session;
  final Map<String, dynamic> plot;
  final FarmingLogLocalRepository repository;
  //
  final Future<String?> Function() readAccessToken;
  // Thêm nút đồng bộ dữ liệu với Backend (nếu có kết nối Internet).
  final FarmerCatalogRepository catalogRepository;

  const FarmingLogListScreen({
    super.key,
    required this.session,
    required this.plot,
    required this.repository,
    required this.readAccessToken,
    required this.catalogRepository,
  });

  @override
  State<FarmingLogListScreen> createState() => _FarmingLogListScreenState();
}

class _FarmingLogListScreenState extends State<FarmingLogListScreen> {
  late Future<List<FarmingLogModel>> futureLogs;
  late final FarmingLogSyncService syncService;

  bool syncing = false;

  //
  Future<void> syncNow() async {
    if (syncing) return;

    setState(() => syncing = true);

    try {
      final result = await syncService.syncPending(
        userId: widget.session.userId,
        readAccessToken: widget.readAccessToken,
      );

      if (!mounted) return;

      setState(refreshLogs);

      final message = result.loginRequired
          ? 'Phiên đăng nhập không còn hợp lệ. '
                'Vui lòng đăng nhập lại khi có mạng.'
          : 'Đồng bộ xong: ${result.synced} thành công, '
                '${result.failed} lỗi nghiệp vụ.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;

      setState(refreshLogs);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi đồng bộ: $error')));
    } finally {
      if (mounted) {
        setState(() => syncing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    syncService = FarmingLogSyncService(
      local: widget.repository,
      remote: FarmingLogRemoteRepository(),
    );
    refreshLogs();
  }

  void refreshLogs() {
    final plotId = widget.plot['plotId'] as int;
    final organizationId = widget.plot['organizationId'] as int;

    futureLogs = widget.repository
        .getLogsByUser(widget.session.userId)
        .then(
          (logs) => logs
              .where(
                (log) =>
                    log.plotId == plotId &&
                    log.organizationId == organizationId,
              )
              .toList(),
        );
  }

  Future<void> openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmingLogSelectionScreen(
          session: widget.session,
          plot: widget.plot,
          catalogRepository: widget.catalogRepository,
          logRepository: widget.repository,
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(refreshLogs);
    }
  }

  void showSavedLocation(FarmingLogModel log) {
    final location = widget.repository.getLocationByLog(
      userId: widget.session.userId,
      farmingLogLocalId: log.localId,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vị trí đã lưu'),
        content: FutureBuilder<FarmingLogLocationModel?>(
          future: location,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text('Đang đọc vị trí…');
            }
            if (snapshot.hasError) {
              return const Text('Không đọc được vị trí từ thiết bị.');
            }
            final saved = snapshot.data;
            if (saved == null) return const Text('Nhật ký này chưa có GPS.');
            final capturedAt = saved.capturedAt.toLocal();
            final localizations = MaterialLocalizations.of(context);
            final date = localizations.formatShortDate(capturedAt);
            final time = localizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(capturedAt),
            );
            return Text(
              'Vĩ độ: ${saved.latitude.toStringAsFixed(6)}\n'
              'Kinh độ: ${saved.longitude.toStringAsFixed(6)}\n'
              'Sai số: ${saved.accuracyMeters.toStringAsFixed(1)} m\n'
              'Lấy lúc: $date $time',
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String activityLabel(String type) {
    switch (type) {
      case 'WATERING':
        return 'Tưới nước';
      case 'FERTILIZING':
        return 'Bón phân';
      case 'SPRAYING':
        return 'Phun thuốc';
      case 'WEEDING':
        return 'Làm cỏ';
      case 'PRUNING':
        return 'Tỉa cành';
      default:
        return 'Công việc khác';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plot['plotCode']}'),
        actions: [
          IconButton(
            tooltip: 'Đồng bộ nhật ký',
            icon: syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            onPressed: syncing ? null : syncNow,
          ),
          IconButton(
            tooltip: 'Làm mới danh sách',
            icon: const Icon(Icons.refresh),
            onPressed: syncing ? null : () => setState(refreshLogs),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: openForm,
        icon: const Icon(Icons.add),
        label: const Text('Ghi nhật ký'),
      ),

      body: FutureBuilder<List<FarmingLogModel>>(
        future: futureLogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi đọc SQLite: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có nhật ký canh tác.\n'
                'Nhấn Ghi nhật ký để bắt đầu.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.agriculture),
                  title: Text(activityLabel(log.activityType)),
                  subtitle: Text(
                    '${log.activityDate}\n'
                    '${log.notes ?? "Không có ghi chú"}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(label: Text(log.syncStatus)),
                  onTap: () => showSavedLocation(log),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
