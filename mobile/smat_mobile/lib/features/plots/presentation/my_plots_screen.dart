import '../data/plot_cache.dart';
import '../../farmer_catalog/data/farmer_catalog_repository.dart';

import '../../farming_logs/data/farming_log_local_repository.dart';
import '../../farming_logs/presentation/farming_log_list_screen.dart';

import 'package:flutter/material.dart';

import '../../../core/security/token_storage.dart';
import '../data/plots_repository.dart';

/// Assigned plots and the status of the latest Backend request.
class MyPlotsScreen extends StatelessWidget {
  final PlotCache cache;
  final FarmerCatalogRepository catalogRepository;
  final Session session;
  final PlotsResult? result;
  final bool busy;
  final Future<void> Function() refresh;
  final Future<String?> Function() readAccessToken;
  final Future<void> Function() prepareOfflineCatalog;

  const MyPlotsScreen({
    super.key,
    required this.cache,
    required this.catalogRepository,
    required this.session,
    required this.result,
    required this.busy,
    required this.refresh,
    required this.readAccessToken,
    required this.prepareOfflineCatalog,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FilledButton.icon(
          onPressed:
              busy ||
                  result?.plots.any((plot) => plot['role'] == 'FARMER') != true
              ? null
              : prepareOfflineCatalog,
          icon: const Icon(Icons.download_for_offline),
          label: const Text('Tải dữ liệu cho tất cả khu đất'),
        ),
      ),
      ListTile(
        title: Text('My Plots • ${session.username}'),
        subtitle: Text(
          result == null
              ? 'Chưa xác định kết nối'
              : result!.online
              ? 'Online • Đã đồng bộ Backend'
              : 'Offline • Dữ liệu đã lưu trên máy',
        ),
      ),
      if (result?.syncedAt != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Lần đồng bộ: ${DateTime.parse(result!.syncedAt!).toLocal()}',
          ),
        ),
      Expanded(
        child: result == null
            ? const Center(child: Text('Nhấn đồng bộ để thử lại.'))
            : result!.plots.isEmpty
            ? Center(
                child: Text(
                  result!.syncedAt == null
                      ? 'Chưa có cache. Cần kết nối Backend lần đầu.'
                      : 'Không có khu đất được phân công.',
                ),
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: result!.plots.length,
                  itemBuilder: (_, i) {
                    final plot = result!.plots[i];

                    return ListTile(
                      leading: const Icon(Icons.grass),

                      title: Text('${plot['plotCode']} • ${plot['plotName']}'),

                      subtitle: Text(
                        'Tổ chức ${plot['organizationId']} • ${plot['role']}',
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: !busy && plot['role'] == 'FARMER'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmingLogListScreen(
                                    session: session,
                                    plot: plot,
                                    repository: FarmingLogLocalRepository(
                                      cache,
                                    ),
                                    readAccessToken: readAccessToken,
                                    catalogRepository: catalogRepository,
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              ),
      ),
    ],
  );
}
