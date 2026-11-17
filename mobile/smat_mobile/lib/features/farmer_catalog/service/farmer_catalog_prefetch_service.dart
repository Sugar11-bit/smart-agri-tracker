import '../../../core/security/token_storage.dart';
import '../data/farmer_catalog_repository.dart';

class CatalogPrefetchResult {
  final int plotsProcessed;
  final int plantingsProcessed;
  final int cyclesLoaded;
  final List<String> errors;

  const CatalogPrefetchResult({
    required this.plotsProcessed,
    required this.plantingsProcessed,
    required this.cyclesLoaded,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

class FarmerCatalogPrefetchService {
  final FarmerCatalogRepository repository;

  FarmerCatalogPrefetchService(this.repository);

  Future<CatalogPrefetchResult> prefetch({
    required Session session,
    required List<Map<String, dynamic>> plots,
  }) async {
    var plotCount = 0;
    var plantingCount = 0;
    var cycleCount = 0;

    final errors = <String>[];

    for (final plot in plots) {
      if (plot['role'] != 'FARMER') continue;

      final organizationId = plot['organizationId'] as int;
      final plotId = plot['plotId'] as int;

      try {
        final plantings = await repository.loadPlantings(
          session: session,
          organizationId: organizationId,
          plotId: plotId,
          allowOfflineFallback: false,
        );

        plotCount++;

        for (final planting in plantings) {
          final plantingId = planting['id'] as int;

          try {
            final cycles = await repository.loadCycles(
              session: session,
              organizationId: organizationId,
              plantingId: plantingId,
              allowOfflineFallback: false,
            );

            plantingCount++;
            cycleCount += cycles.length;
          } catch (error) {
            errors.add(
              'Không tải được Cycle của '
              'Planting $plantingId: $error',
            );
          }
        }
      } catch (error) {
        errors.add(
          'Không tải được Planting của '
          'Plot $plotId: $error',
        );
      }
    }

    return CatalogPrefetchResult(
      plotsProcessed: plotCount,
      plantingsProcessed: plantingCount,
      cyclesLoaded: cycleCount,
      errors: errors,
    );
  }
}
