import 'package:flutter/material.dart';

import '../../../core/security/token_storage.dart';
import '../../farmer_catalog/data/farmer_catalog_repository.dart';
import '../data/farming_log_local_repository.dart';
import 'farming_log_form_screen.dart';
import '../../farmer_catalog/service/farmer_catalog_prefetch_service.dart';

class FarmingLogSelectionScreen extends StatefulWidget {
  final Session session;
  final Map<String, dynamic> plot;
  final FarmerCatalogRepository catalogRepository;
  final FarmingLogLocalRepository logRepository;

  const FarmingLogSelectionScreen({
    super.key,
    required this.session,
    required this.plot,
    required this.catalogRepository,
    required this.logRepository,
  });

  @override
  State<FarmingLogSelectionScreen> createState() =>
      _FarmingLogSelectionScreenState();
}

class _FarmingLogSelectionScreenState extends State<FarmingLogSelectionScreen> {
  List<Map<String, dynamic>> plantings = [];
  List<Map<String, dynamic>> cycles = [];

  int? selectedPlantingId;
  int? selectedCycleId;

  bool loadingPlantings = false;
  bool loadingCycles = false;
  bool preparingOfflineData = false;

  String? errorMessage;

  // Ngăn kết quả của request cũ ghi đè
  // kết quả khi Farmer đã chọn Planting mới.
  int cycleRequestVersion = 0;

  int get organizationId => widget.plot['organizationId'] as int;

  int get plotId => widget.plot['plotId'] as int;

  Future<void> prepareOfflineData() async {
    if (preparingOfflineData) return;

    setState(() {
      preparingOfflineData = true;
      errorMessage = null;
    });

    try {
      final service = FarmerCatalogPrefetchService(widget.catalogRepository);

      final result = await service.prefetch(
        session: widget.session,
        plots: [widget.plot],
      );

      if (!mounted) return;

      if (result.hasErrors) {
        setState(() {
          errorMessage =
              'Tải chưa hoàn tất. '
              '${result.errors.length} yêu cầu thất bại.';
        });
        return;
      }

      await loadPlantings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xử lý ${result.plantingsProcessed} '
            'Planting và ${result.cyclesLoaded} Cycle. '
            'Kiểm tra dữ liệu cache trước khi offline.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Chuẩn bị dữ liệu chưa hoàn tất: $error';
      });
    } finally {
      if (mounted) {
        setState(() => preparingOfflineData = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadPlantings();
  }

  Future<void> loadPlantings() async {
    setState(() {
      loadingPlantings = true;
      errorMessage = null;

      plantings = [];
      cycles = [];
      selectedPlantingId = null;
      selectedCycleId = null;

      cycleRequestVersion++;
    });

    try {
      final result = await widget.catalogRepository.loadPlantings(
        session: widget.session,
        organizationId: organizationId,
        plotId: plotId,
      );

      if (!mounted) return;

      setState(() {
        plantings = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Không tải được cây trồng: $error';
      });
    } finally {
      if (mounted) {
        setState(() => loadingPlantings = false);
      }
    }
  }

  Future<void> selectPlanting(int? plantingId) async {
    final requestVersion = ++cycleRequestVersion;

    setState(() {
      selectedPlantingId = plantingId;
      selectedCycleId = null;
      cycles = [];
      errorMessage = null;
      loadingCycles = plantingId != null;
    });

    if (plantingId == null) return;

    try {
      final result = await widget.catalogRepository.loadCycles(
        session: widget.session,
        organizationId: organizationId,
        plantingId: plantingId,
      );

      if (!mounted || requestVersion != cycleRequestVersion) {
        return;
      }

      setState(() {
        cycles = result;
      });
    } catch (error) {
      if (!mounted || requestVersion != cycleRequestVersion) {
        return;
      }

      setState(() {
        errorMessage = 'Không tải được kỳ sản xuất: $error';
      });
    } finally {
      if (mounted && requestVersion == cycleRequestVersion) {
        setState(() => loadingCycles = false);
      }
    }
  }

  Future<void> openFarmingLogForm() async {
    final plantingIsValid = plantings.any(
      (p) => p['id'] == selectedPlantingId && p['plotId'] == plotId,
    );

    final cycleIsValid = cycles.any(
      (c) =>
          c['id'] == selectedCycleId &&
          c['organizationId'] == organizationId &&
          c['plantingId'] == selectedPlantingId,
    );

    if (!plantingIsValid || !cycleIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cây trồng hoặc kỳ sản xuất không hợp lệ'),
        ),
      );

      return;
    }
    if (selectedPlantingId == null || selectedCycleId == null) {
      return;
    } else {
      final plantingIsValid = plantings.any(
        (p) =>
            p['id'] == selectedPlantingId &&
            p['plotId'] == plotId &&
            p['status'] == 'ACTIVE',
      );

      final cycleIsValid = cycles.any(
        (c) =>
            c['id'] == selectedCycleId &&
            c['plantingId'] == selectedPlantingId &&
            c['organizationId'] == organizationId,
      );

      if (!plantingIsValid || !cycleIsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cây trồng hoặc kỳ sản xuất không hợp lệ.'),
          ),
        );
        return;
      }
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmingLogFormScreen(
          session: widget.session,
          plot: widget.plot,
          repository: widget.logRepository,
          plantingId: selectedPlantingId!,
          productionCycleId: selectedCycleId!,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn cây trồng và kỳ sản xuất')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.grass),
              title: Text('${widget.plot['plotName']}'),
              subtitle: Text('Plot: ${widget.plot['plotCode']}'),
            ),
          ),
          //
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: preparingOfflineData || loadingPlantings || loadingCycles
                ? null
                : prepareOfflineData,
            icon: preparingOfflineData
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_for_offline),
            label: Text(
              preparingOfflineData
                  ? 'Đang chuẩn bị dữ liệu...'
                  : 'Chuẩn bị dữ liệu offline',
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '1. Chọn cây trồng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),

          const SizedBox(height: 10),

          if (loadingPlantings) const LinearProgressIndicator(),

          DropdownButtonFormField<int>(
            key: ValueKey('planting-${selectedPlantingId ?? "none"}'),
            initialValue: selectedPlantingId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Planting',
              border: OutlineInputBorder(),
            ),
            items: plantings.map((planting) {
              return DropdownMenuItem<int>(
                value: planting['id'] as int,
                child: Text(
                  '${planting['plantingCode']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: loadingPlantings || preparingOfflineData
                ? null
                : selectPlanting,
          ),

          if (!loadingPlantings && plantings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Chưa có dữ liệu Planting. '
                'Hãy tải dữ liệu khi có mạng.',
              ),
            ),

          const SizedBox(height: 24),

          const Text(
            '2. Chọn kỳ sản xuất',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),

          const SizedBox(height: 10),

          if (loadingCycles) const LinearProgressIndicator(),

          DropdownButtonFormField<int>(
            key: ValueKey(
              'cycle-$selectedPlantingId-'
              '${selectedCycleId ?? "none"}',
            ),
            initialValue: selectedCycleId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Production Cycle',
              border: OutlineInputBorder(),
            ),
            items: cycles.map((cycle) {
              return DropdownMenuItem<int>(
                value: cycle['id'] as int,
                child: Text(
                  '${cycle['cycleCode']} '
                  '(${cycle['status']})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged:
                selectedPlantingId == null ||
                    loadingCycles ||
                    preparingOfflineData
                ? null
                : (value) {
                    setState(() {
                      selectedCycleId = value;
                    });
                  },
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed:
                selectedPlantingId != null &&
                    selectedCycleId != null &&
                    !loadingPlantings &&
                    !loadingCycles &&
                    !preparingOfflineData
                ? openFarmingLogForm
                : null,
            icon: const Icon(Icons.edit_note),
            label: const Text('Tiếp tục ghi nhật ký'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: loadingPlantings || loadingCycles || preparingOfflineData
                ? null
                : loadPlantings,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại danh sách'),
          ),
        ],
      ),
    );
  }
}
