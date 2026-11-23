import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/network/api_config.dart';

enum MediaErrorKind { temporary, authentication, permanent }

class MediaSyncException implements Exception {
  final MediaErrorKind kind;
  final String message;

  const MediaSyncException(this.kind, this.message);

  @override
  String toString() => message;
}

class PhotoUploadAck {
  final int id;
  final int farmingLogId;
  final String clientPhotoId;

  const PhotoUploadAck({
    required this.id,
    required this.farmingLogId,
    required this.clientPhotoId,
  });
}

class FarmingLogMediaRemoteRepository {
  final http.Client client;

  FarmingLogMediaRemoteRepository({http.Client? client})
    : client = client ?? http.Client();

  Uri _uri(int serverLogId, String suffix) {
    return Uri.parse(
      '${ApiConfig.baseUrl}'
      '/api/v1/me/farming-logs/$serverLogId/$suffix',
    );
  }

  void _checkStatus(int status) {
    if (status == 401) {
      throw const MediaSyncException(
        MediaErrorKind.authentication,
        'JWT không hợp lệ hoặc đã hết hạn',
      );
    }

    if (status == 408 || status == 429 || status >= 500) {
      throw MediaSyncException(
        MediaErrorKind.temporary,
        'Backend tạm thời gặp lỗi: HTTP $status',
      );
    }

    if (status != 200 && status != 201) {
      throw MediaSyncException(
        MediaErrorKind.permanent,
        'Backend từ chối dữ liệu: HTTP $status',
      );
    }
  }

  Future<PhotoUploadAck> uploadPhoto({
    required int serverLogId,
    required String clientPhotoId,
    required String localPath,
    required String token,
  }) async {
    final file = File(localPath);

    if (!await file.exists()) {
      throw const MediaSyncException(
        MediaErrorKind.permanent,
        'File ảnh không còn tồn tại',
      );
    }

    final extension = p.extension(localPath).toLowerCase();

    if (!{'.jpg', '.jpeg', '.png'}.contains(extension)) {
      throw const MediaSyncException(
        MediaErrorKind.permanent,
        'Backend hiện chỉ hỗ trợ JPEG/PNG',
      );
    }

    final length = await file.length();

    if (length == 0 || length > 5 * 1024 * 1024) {
      throw const MediaSyncException(
        MediaErrorKind.permanent,
        'Ảnh rỗng hoặc vượt giới hạn 5 MB',
      );
    }

    final request = http.MultipartRequest('POST', _uri(serverLogId, 'photos'));

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['clientPhotoId'] = clientPhotoId;

    request.files.add(await http.MultipartFile.fromPath('file', localPath));

    late final http.StreamedResponse response;

    try {
      response = await client
          .send(request)
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Upload ảnh quá thời gian chờ',
      );
    } on SocketException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Mất kết nối trong lúc upload ảnh',
      );
    } on http.ClientException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Không kết nối được Backend',
      );
    }

    final body = await response.stream.bytesToString().timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Không nhận đủ response upload ảnh',
      ),
    );

    _checkStatus(response.statusCode);

    try {
      final data = jsonDecode(body) as Map<String, dynamic>;

      final id = data['id'];
      final logId = data['farmingLogId'];
      final photoId = data['clientPhotoId'];

      if (id is! int ||
          id <= 0 ||
          logId != serverLogId ||
          photoId != clientPhotoId) {
        throw const FormatException('Response ảnh không đúng UUID hoặc Log');
      }

      return PhotoUploadAck(
        id: id,
        farmingLogId: logId as int,
        clientPhotoId: photoId as String,
      );
    } catch (_) {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Không xác minh được response ảnh',
      );
    }
  }

  Future<void> uploadLocation({
    required int serverLogId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required String capturedAt,
    required String token,
  }) async {
    late final http.Response response;

    try {
      response = await client
          .put(
            _uri(serverLogId, 'location'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'accuracyMeters': accuracyMeters,
              'capturedAt': capturedAt,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Đồng bộ GPS quá thời gian chờ',
      );
    } on SocketException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Mất kết nối khi gửi GPS',
      );
    } on http.ClientException {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Không kết nối được Backend',
      );
    }

    _checkStatus(response.statusCode);

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final responseId = data['farmingLogId'];
      final responseLat = data['latitude'];
      final responseLon = data['longitude'];
      final responseAccuracy = data['accuracyMeters'];
      final responseTime = data['capturedAt'];

      if (responseId != serverLogId ||
          responseLat is! num ||
          responseLon is! num ||
          responseAccuracy is! num ||
          responseTime is! String ||
          responseLat.toDouble() != latitude ||
          responseLon.toDouble() != longitude ||
          responseAccuracy.toDouble() != accuracyMeters ||
          DateTime.parse(responseTime).toUtc() !=
              DateTime.parse(capturedAt).toUtc()) {
        throw const FormatException('Response GPS không khớp dữ liệu gửi');
      }
    } catch (_) {
      throw const MediaSyncException(
        MediaErrorKind.temporary,
        'Không xác minh được response GPS',
      );
    }
  }
}
