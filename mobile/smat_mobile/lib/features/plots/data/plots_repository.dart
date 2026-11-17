import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import 'plot_cache.dart';

class PlotsResult {
  final List<Map<String, dynamic>> plots;
  final bool online;
  final String? syncedAt;
  PlotsResult(this.plots, this.online, this.syncedAt);
}

class PlotsRepository {
  final ApiClient api;
  final PlotCache cache;
  PlotsRepository(this.api, this.cache);
  Future<PlotsResult> load(Session session) async {
    dynamic response;
    try {
      response = await api.request('/api/v1/me/plots', token: session.token);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (_) {
      return PlotsResult(
        await cache.read(session.userId),
        false,
        await cache.lastSync(session.userId),
      );
    }
    final plots = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    await cache.replace(session.userId, plots);
    return PlotsResult(plots, true, await cache.lastSync(session.userId));
  }
}
