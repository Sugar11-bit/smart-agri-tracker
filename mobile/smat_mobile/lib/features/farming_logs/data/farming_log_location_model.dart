class FarmingLogLocationModel {
  final String farmingLogLocalId;
  final int userId;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  const FarmingLogLocationModel({
    required this.farmingLogLocalId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  Map<String, Object?> toDatabase() {
    return {
      'farming_log_local_id': farmingLogLocalId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'captured_at': capturedAt.toUtc().toIso8601String(),
    };
  }

  factory FarmingLogLocationModel.fromDatabase(Map<String, Object?> row) {
    return FarmingLogLocationModel(
      farmingLogLocalId: row['farming_log_local_id'] as String,
      userId: row['user_id'] as int,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      accuracyMeters: (row['accuracy_meters'] as num).toDouble(),
      capturedAt: DateTime.parse(row['captured_at'] as String),
    );
  }
}
