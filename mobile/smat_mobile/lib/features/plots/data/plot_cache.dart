import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class PlotCache {
  Database? _db;

  // Tạo bảng farming_log_locations
  Future<void> _createFarmingLogLocations(DatabaseExecutor db) async {
    await db.execute('''
    CREATE TABLE farming_log_locations (
      farming_log_local_id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL,

      latitude REAL NOT NULL
        CHECK(latitude BETWEEN -90 AND 90),

      longitude REAL NOT NULL
        CHECK(longitude BETWEEN -180 AND 180),

      accuracy_meters REAL NOT NULL
        CHECK(accuracy_meters >= 0),

      captured_at TEXT NOT NULL,

      FOREIGN KEY (farming_log_local_id)
        REFERENCES farming_logs(local_id)
        ON DELETE RESTRICT
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_farming_log_locations_user
    ON farming_log_locations(
      user_id
    )
  ''');
  }

  Future<void> _addLocationSyncColumns(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE farming_log_locations
      ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'
      CHECK (
        sync_status IN (
          'PENDING',
          'SYNCING',
          'SYNCED',
          'FAILED'
        )
      )
    ''');

    await db.execute('''
      ALTER TABLE farming_log_locations
      ADD COLUMN last_error TEXT
    ''');

    await db.execute('''
      ALTER TABLE farming_log_locations
      ADD COLUMN server_received_at TEXT
    ''');

    await db.execute('''
      CREATE INDEX idx_farming_log_locations_sync
      ON farming_log_locations(user_id, sync_status)
    ''');
  }
  //tạo bảng farming_log_photos

  Future<void> _createFarmingLogPhotos(DatabaseExecutor db) async {
    await db.execute('''
    CREATE TABLE farming_log_photos (
      local_photo_id TEXT PRIMARY KEY,
      farming_log_local_id TEXT NOT NULL,
      user_id INTEGER NOT NULL,
      local_path TEXT NOT NULL,
      created_at TEXT NOT NULL,

      sync_status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (
          sync_status IN (
            'PENDING',
            'SYNCING',
            'SYNCED',
            'FAILED'
          )
        ),

      server_photo_id INTEGER,
      last_error TEXT,

      FOREIGN KEY (farming_log_local_id)
        REFERENCES farming_logs(local_id)
        ON DELETE RESTRICT
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_farming_log_photos_log
    ON farming_log_photos(
      user_id,
      farming_log_local_id
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_farming_log_photos_sync
    ON farming_log_photos(
      user_id,
      sync_status
    )
  ''');
  }

  Future<void> _createCatalogMetadata(DatabaseExecutor db) async {
    await db.execute('''
    CREATE TABLE catalog_cache_metadata (
      user_id INTEGER NOT NULL,
      organization_id INTEGER NOT NULL,
      scope_type TEXT NOT NULL
        CHECK(scope_type IN ('PLANTINGS', 'CYCLES')),
      parent_id INTEGER NOT NULL,
      fetched_at TEXT NOT NULL,
      item_count INTEGER NOT NULL
        CHECK(item_count >= 0),

      PRIMARY KEY (
        user_id,
        organization_id,
        scope_type,
        parent_id
      )
    )
  ''');
  }

  Future<void> _createFarmingLogs(DatabaseExecutor db) async {
    await db.execute('''
    CREATE TABLE farming_logs (
      local_id TEXT PRIMARY KEY,

      user_id INTEGER NOT NULL,
      organization_id INTEGER NOT NULL,
      plot_id INTEGER NOT NULL,
      planting_id INTEGER NOT NULL,
      production_cycle_id INTEGER NOT NULL,

      activity_type TEXT NOT NULL,
      activity_date TEXT NOT NULL,
      notes TEXT,
      client_created_at TEXT NOT NULL,

      sync_status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (
          sync_status IN (
            'PENDING',
            'SYNCING',
            'SYNCED',
            'FAILED'
          )
        ),

      server_id INTEGER,
      server_received_at TEXT,
      last_error TEXT,

      CHECK (
        server_id IS NULL
        OR sync_status = 'SYNCED'
      )
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_local_farming_user_status
    ON farming_logs(user_id, sync_status)
  ''');

    await db.execute('''
    CREATE INDEX idx_local_farming_plot
    ON farming_logs(
      user_id,
      organization_id,
      plot_id
    )
  ''');
  }

  Future<void> _createPlantingCycleCache(DatabaseExecutor db) async {
    await db.execute('''
    CREATE TABLE cached_plantings (
      user_id INTEGER NOT NULL,
      organization_id INTEGER NOT NULL,
      plot_id INTEGER NOT NULL,
      planting_id INTEGER NOT NULL,
      crop_type_id INTEGER NOT NULL,
      planting_code TEXT NOT NULL,
      status TEXT NOT NULL,

      PRIMARY KEY (
        user_id,
        organization_id,
        planting_id
      )
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_cached_plantings_plot
    ON cached_plantings(
      user_id,
      organization_id,
      plot_id
    )
  ''');

    await db.execute('''
    CREATE TABLE cached_production_cycles (
      user_id INTEGER NOT NULL,
      organization_id INTEGER NOT NULL,
      planting_id INTEGER NOT NULL,
      cycle_id INTEGER NOT NULL,
      cycle_code TEXT NOT NULL,
      cycle_year INTEGER,
      start_date TEXT NOT NULL,
      end_date TEXT,
      status TEXT NOT NULL,

      PRIMARY KEY (
        user_id,
        organization_id,
        cycle_id
      )
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_cached_cycles_planting
    ON cached_production_cycles(
      user_id,
      organization_id,
      planting_id
    )
  ''');
  }

  Future<Database> get database async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'smat_farmer_v1.db'),
    version: 7,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },

    onCreate: (db, version) async {
      // Bảng của version 1
      await db.execute('''
          CREATE TABLE plots (
            user_id INTEGER NOT NULL,
            plot_id INTEGER NOT NULL,
            payload TEXT NOT NULL,
            PRIMARY KEY(user_id, plot_id)
          )
        ''');

      await db.execute('''
          CREATE TABLE sync_state (
            user_id INTEGER PRIMARY KEY,
            synced_at TEXT NOT NULL
          )
        ''');

      // Bảng mới khi nâng cấp lên version 2
      await _createFarmingLogs(db);

      // Bảng mới khi nâng cấp lên version 3
      await _createPlantingCycleCache(db);

      // Bảng mới khi nâng cấp lên version 4
      await _createCatalogMetadata(db);

      // Bảng mới khi nâng cấp lên version 5
      await _createFarmingLogPhotos(db);

      // Bảng mới khi nâng cấp lên version 6
      await _createFarmingLogLocations(db);

      // Bảng mới khi nâng cấp lên version 7
      await _addLocationSyncColumns(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createFarmingLogs(db);
      }

      if (oldVersion < 3) {
        await _createPlantingCycleCache(db);
      }

      if (oldVersion < 4) {
        await _createCatalogMetadata(db);
      }

      if (oldVersion < 5) {
        await _createFarmingLogPhotos(db);
      }
      if (oldVersion < 6) {
        await _createFarmingLogLocations(db);
      }

      if (oldVersion < 7) {
        await _addLocationSyncColumns(db);
      }
    },
  );

  Future<void> replace(int userId, List<Map<String, dynamic>> plots) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('plots', where: 'user_id = ?', whereArgs: [userId]);
      for (final plot in plots) {
        await txn.insert('plots', {
          'user_id': userId,
          'plot_id': plot['plotId'],
          'payload': jsonEncode(plot),
        });
      }
      await txn.insert('sync_state', {
        'user_id': userId,
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> read(int userId) async {
    final rows = await (await database).query(
      'plots',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'plot_id',
    );
    return rows
        .map((r) => jsonDecode(r['payload'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<String?> lastSync(int userId) async {
    final rows = await (await database).query(
      'sync_state',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.isEmpty ? null : rows.first['synced_at'] as String;
  }
}
