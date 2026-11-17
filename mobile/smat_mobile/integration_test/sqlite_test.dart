import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smat_mobile/farmer_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android SQLite isolates users, persists and replaces empty lists',
    (_) async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE plots (user_id INTEGER NOT NULL, plot_id INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(user_id, plot_id))',
          );
          await db.execute(
            'CREATE TABLE sync_state (user_id INTEGER PRIMARY KEY, synced_at TEXT NOT NULL)',
          );
        },
      );
      final cache = TestCache(db);
      try {
        await cache.replace(1, [
          {'plotId': 10, 'plotName': 'Test plot'},
        ]);
        await cache.replace(2, [
          {'plotId': 10, 'plotName': 'Other owner'},
        ]);
        expect((await cache.read(1)).single['plotName'], 'Test plot');
        expect((await cache.read(2)).single['plotName'], 'Other owner');
        expect(await cache.read(3), isEmpty);
        final offline = PlotsRepository(
          ApiClient(
            client: MockClient(
              (_) async => throw http.ClientException('offline'),
            ),
          ),
          cache,
        );
        expect(
          (await offline.load(Session('test-only', 1, 'a'))).online,
          isFalse,
        );
        expect(
          (await offline.load(Session('test-only', 3, 'b'))).plots,
          isEmpty,
        );
        await cache.replace(1, []);
        expect(await cache.read(1), isEmpty);
        expect(await cache.read(2), hasLength(1));
        expect(await cache.lastSync(1), isNotNull);
      } finally {
        await db.close();
      }
    },
  );
}

class TestCache extends PlotCache {
  final Database db;
  TestCache(this.db);
  @override
  Future<Database> get database async => db;
}
