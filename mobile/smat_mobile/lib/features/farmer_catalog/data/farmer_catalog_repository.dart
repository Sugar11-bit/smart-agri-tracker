// import 'dart:convert';
import 'catalog_cache_metadata_repository.dart';

import 'package:sqflite/sqflite.dart';

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import '../../plots/data/plot_cache.dart';

class FarmerCatalogRepository {
  final ApiClient api;
  final PlotCache cache;

  FarmerCatalogRepository(this.api, this.cache);

  CatalogCacheMetadataRepository get metadata =>
      CatalogCacheMetadataRepository(cache);

  Future<List<Map<String, dynamic>>> loadPlantings({
    required Session session,
    required int organizationId,
    required int plotId,
    bool allowOfflineFallback = true,
  }) async {
    try {
      final response = await api.request(
        '/api/v1/me/plantings'
        '?organizationId=$organizationId'
        '&plotId=$plotId',
        token: session.token,
      );

      final data = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final db = await cache.database;

      await db.transaction((txn) async {
        await txn.delete(
          'cached_plantings',
          where: '''
            user_id = ?
            AND organization_id = ?
            AND plot_id = ?
          ''',
          whereArgs: [session.userId, organizationId, plotId],
        );

        for (final item in data) {
          await txn.insert('cached_plantings', {
            'user_id': session.userId,
            'organization_id': organizationId,
            'plot_id': plotId,
            'planting_id': item['id'],
            'crop_type_id': item['cropTypeId'],
            'planting_code': item['plantingCode'],
            'status': item['status'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await metadata.saveInTransaction(
          txn: txn,
          userId: session.userId,
          organizationId: organizationId,
          scopeType: 'PLANTINGS',
          parentId: plotId,
          itemCount: data.length,
        );
      });

      return data;
    } on ApiFailure {
      // 401/403/404 không được che bằng cache cũ.
      rethrow;
    } on FormatException {
      rethrow;
    } on SocketException {
      if (!allowOfflineFallback) rethrow;
      return readCachedPlantings(
        userId: session.userId,
        organizationId: organizationId,
        plotId: plotId,
      );
    } on TimeoutException {
      if (!allowOfflineFallback) rethrow;
      return readCachedPlantings(
        userId: session.userId,
        organizationId: organizationId,
        plotId: plotId,
      );
    } on http.ClientException {
      if (!allowOfflineFallback) rethrow;
      return readCachedPlantings(
        userId: session.userId,
        organizationId: organizationId,
        plotId: plotId,
      );
    }
  }

  Future<List<Map<String, dynamic>>> readCachedPlantings({
    required int userId,
    required int organizationId,
    required int plotId,
  }) async {
    final db = await cache.database;

    final rows = await db.query(
      'cached_plantings',
      where: '''
        user_id = ?
        AND organization_id = ?
        AND plot_id = ?
      ''',
      whereArgs: [userId, organizationId, plotId],
      orderBy: 'planting_code ASC',
    );

    return rows
        .map(
          (row) => {
            'id': row['planting_id'],
            'plotId': row['plot_id'],
            'cropTypeId': row['crop_type_id'],
            'plantingCode': row['planting_code'],
            'status': row['status'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadCycles({
    required Session session,
    required int organizationId,
    required int plantingId,
    bool allowOfflineFallback = true,
  }) async {
    try {
      final response = await api.request(
        '/api/v1/me/production-cycles'
        '?organizationId=$organizationId'
        '&plantingId=$plantingId',
        token: session.token,
      );

      final data = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final db = await cache.database;

      await db.transaction((txn) async {
        await txn.delete(
          'cached_production_cycles',
          where: '''
            user_id = ?
            AND organization_id = ?
            AND planting_id = ?
          ''',
          whereArgs: [session.userId, organizationId, plantingId],
        );

        for (final item in data) {
          await txn.insert('cached_production_cycles', {
            'user_id': session.userId,
            'organization_id': organizationId,
            'planting_id': plantingId,
            'cycle_id': item['id'],
            'cycle_code': item['cycleCode'],
            'cycle_year': item['cycleYear'],
            'start_date': item['startDate'],
            'end_date': item['endDate'],
            'status': item['status'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await metadata.saveInTransaction(
          txn: txn,
          userId: session.userId,
          organizationId: organizationId,
          scopeType: 'CYCLES',
          parentId: plantingId,
          itemCount: data.length,
        );
      });

      return data;
    } on ApiFailure {
      rethrow;
    } on FormatException {
      rethrow;
    } on SocketException {
      if (!allowOfflineFallback) rethrow;
      return readCachedCycles(
        userId: session.userId,
        organizationId: organizationId,
        plantingId: plantingId,
      );
    } on TimeoutException {
      if (!allowOfflineFallback) rethrow;
      return readCachedCycles(
        userId: session.userId,
        organizationId: organizationId,
        plantingId: plantingId,
      );
    } on http.ClientException {
      if (!allowOfflineFallback) rethrow;
      return readCachedCycles(
        userId: session.userId,
        organizationId: organizationId,
        plantingId: plantingId,
      );
    }
  }

  Future<List<Map<String, dynamic>>> readCachedCycles({
    required int userId,
    required int organizationId,
    required int plantingId,
  }) async {
    final db = await cache.database;

    final rows = await db.query(
      'cached_production_cycles',
      where: '''
        user_id = ?
        AND organization_id = ?
        AND planting_id = ?
      ''',
      whereArgs: [userId, organizationId, plantingId],
      orderBy: 'start_date DESC',
    );

    return rows
        .map(
          (row) => {
            'id': row['cycle_id'],
            'organizationId': row['organization_id'],
            'plantingId': row['planting_id'],
            'cycleCode': row['cycle_code'],
            'cycleYear': row['cycle_year'],
            'startDate': row['start_date'],
            'endDate': row['end_date'],
            'status': row['status'],
          },
        )
        .toList();
  }
}
