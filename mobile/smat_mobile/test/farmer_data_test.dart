import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smat_mobile/farmer_data.dart';

class MemoryStorage extends TokenStorage {
  Session? saved;
  @override
  Future<void> save(Session s) async {
    saved = s;
  }
}

class MemoryCache extends PlotCache {
  final rows = <int, List<Map<String, dynamic>>>{};
  @override
  Future<void> replace(int id, List<Map<String, dynamic>> plots) async {
    rows[id] = plots;
  }

  @override
  Future<List<Map<String, dynamic>>> read(int id) async => rows[id] ?? [];
  @override
  Future<String?> lastSync(int id) async =>
      rows.containsKey(id) ? '2026-11-02T00:00:00Z' : null;
}

void main() {
  test('Login verifies /me before storing session', () async {
    final storage = MemoryStorage();
    final api = ApiClient(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/login')) {
          expect(jsonDecode(r.body)['username'], 'farmer');
          return http.Response('{"accessToken":"test-only"}', 200);
        }
        expect(r.headers['Authorization'], 'Bearer test-only');
        expect(storage.saved, isNull);
        return http.Response('{"userId":7,"username":"farmer"}', 200);
      }),
    );
    expect(
      (await AuthRepository(api, storage).login('farmer', 'test-only')).userId,
      7,
    );
    expect(storage.saved?.userId, 7);
  });
  test('Failed /me never stores token', () async {
    final storage = MemoryStorage();
    final api = ApiClient(
      client: MockClient(
        (r) async => r.url.path.endsWith('/login')
            ? http.Response('{"accessToken":"test-only"}', 200)
            : http.Response('', 401),
      ),
    );
    await expectLater(
      AuthRepository(api, storage).login('f', 'test-only'),
      throwsA(isA<ApiFailure>()),
    );
    expect(storage.saved, isNull);
  });
  test(
    'Offline cache is isolated; empty online response removes revoked plots',
    () async {
      final cache = MemoryCache();
      await cache.replace(1, [
        {'plotId': 10},
      ]);
      final offline = PlotsRepository(
        ApiClient(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
        cache,
      );
      expect(
        (await offline.load(Session('test-only', 1, 'a'))).plots,
        hasLength(1),
      );
      expect((await offline.load(Session('test-only', 2, 'b'))).plots, isEmpty);
      final online = PlotsRepository(
        ApiClient(client: MockClient((_) async => http.Response('[]', 200))),
        cache,
      );
      expect((await online.load(Session('test-only', 1, 'a'))).online, isTrue);
      expect(await cache.read(1), isEmpty);
    },
  );
  test(
    '401, 403, 500 and malformed JSON never fall back to offline cache',
    () async {
      for (final status in [401, 403, 500, 200]) {
        final repo = PlotsRepository(
          ApiClient(
            client: MockClient((_) async => http.Response('invalid', status)),
          ),
          MemoryCache(),
        );
        await expectLater(
          repo.load(Session('test-only', 1, 'a')),
          throwsA(status == 200 ? isA<FormatException>() : isA<ApiFailure>()),
        );
      }
    },
  );
}
