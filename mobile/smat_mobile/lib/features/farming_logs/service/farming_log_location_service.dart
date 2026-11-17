import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum GpsErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class GpsException implements Exception {
  final GpsErrorType type;
  final String message;

  const GpsException(this.type, this.message);

  @override
  String toString() => message;
}

class GpsReading {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });
}

class FarmingLogLocationService {
  Future<GpsReading> getCurrentLocation() async {
    // 1. Kiểm tra dịch vụ vị trí của thiết bị.
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw const GpsException(
        GpsErrorType.serviceDisabled,
        'Thiết bị đang tắt dịch vụ vị trí',
      );
    }

    // 2. Kiểm tra quyền của ứng dụng.
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const GpsException(
        GpsErrorType.permissionDeniedForever,
        'Quyền vị trí đã bị từ chối lâu dài',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const GpsException(
        GpsErrorType.permissionDenied,
        'Farmer chưa cấp quyền vị trí',
      );
    }

    // 3. Lấy vị trí hiện tại.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          !position.accuracy.isFinite ||
          position.accuracy < 0 ||
          position.latitude < -90 ||
          position.latitude > 90 ||
          position.longitude < -180 ||
          position.longitude > 180) {
        throw const GpsException(
          GpsErrorType.unavailable,
          'Tọa độ trả về không hợp lệ',
        );
      }

      return GpsReading(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp.toUtc(),
      );
    } on TimeoutException {
      throw const GpsException(
        GpsErrorType.timeout,
        'Không lấy được GPS trong 30 giây',
      );
    } on GpsException {
      rethrow;
    } catch (error) {
      throw GpsException(
        GpsErrorType.unavailable,
        'Không lấy được vị trí: $error',
      );
    }
  }
}
