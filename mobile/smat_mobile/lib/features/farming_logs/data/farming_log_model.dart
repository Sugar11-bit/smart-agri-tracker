class FarmingLogModel {
  final String localId;
  final int userId;
  final int organizationId;
  final int plotId;
  final int plantingId;
  final int productionCycleId;

  final String activityType;
  final String activityDate;
  final String? notes;
  final String clientCreatedAt;

  final String syncStatus;
  final int? serverId;
  final String? serverReceivedAt;
  final String? lastError;

  const FarmingLogModel({
    required this.localId,
    required this.userId,
    required this.organizationId,
    required this.plotId,
    required this.plantingId,
    required this.productionCycleId,
    required this.activityType,
    required this.activityDate,
    required this.notes,
    required this.clientCreatedAt,
    this.syncStatus = 'PENDING',
    this.serverId,
    this.serverReceivedAt,
    this.lastError,
  });

  Map<String, Object?> toDatabase() {
    return {
      'local_id': localId,
      'user_id': userId,
      'organization_id': organizationId,
      'plot_id': plotId,
      'planting_id': plantingId,
      'production_cycle_id': productionCycleId,
      'activity_type': activityType,
      'activity_date': activityDate,
      'notes': notes,
      'client_created_at': clientCreatedAt,
      'sync_status': syncStatus,
      'server_id': serverId,
      'server_received_at': serverReceivedAt,
      'last_error': lastError,
    };
  }

  factory FarmingLogModel.fromDatabase(Map<String, Object?> row) {
    return FarmingLogModel(
      localId: row['local_id'] as String,
      userId: row['user_id'] as int,
      organizationId: row['organization_id'] as int,
      plotId: row['plot_id'] as int,
      plantingId: row['planting_id'] as int,
      productionCycleId: row['production_cycle_id'] as int,
      activityType: row['activity_type'] as String,
      activityDate: row['activity_date'] as String,
      notes: row['notes'] as String?,
      clientCreatedAt: row['client_created_at'] as String,
      syncStatus: row['sync_status'] as String,
      serverId: row['server_id'] as int?,
      serverReceivedAt: row['server_received_at'] as String?,
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'clientLogId': localId,
      'organizationId': organizationId,
      'plotId': plotId,
      'plantingId': plantingId,
      'productionCycleId': productionCycleId,
      'activityType': activityType,
      'activityDate': activityDate,
      'notes': notes,
      'clientCreatedAt': clientCreatedAt,
    };
  }
}
