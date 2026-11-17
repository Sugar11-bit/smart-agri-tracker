//Giao tiếp với backend để đồng bộ nhật ký canh tác

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import 'farming_log_model.dart';

enum SyncErrorType { temporary, authentication, permanent }

class SyncRemoteException implements Exception {
  final SyncErrorType type;
  final String message;

  const SyncRemoteException(this.type, this.message);

  @override
  String toString() => message;
}

class FarmingLogAck {
  final int serverId;
  final String clientLogId;
  final String serverReceivedAt;

  const FarmingLogAck({
    required this.serverId,
    required this.clientLogId,
    required this.serverReceivedAt,
  });
}

class FarmingLogRemoteRepository {
  Future<FarmingLogAck> upload({
    required FarmingLogModel log,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.farmingLogs}');

    late final http.Response response;

    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(log.toApiJson()),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const SyncRemoteException(
        SyncErrorType.temporary,
        'Backend không phản hồi trong thời gian quy định',
      );
    } on http.ClientException {
      throw const SyncRemoteException(
        SyncErrorType.temporary,
        'Không kết nối được Backend',
      );
    }

    final status = response.statusCode;

    if (status == 401) {
      throw const SyncRemoteException(
        SyncErrorType.authentication,
        'JWT hết hạn hoặc không hợp lệ',
      );
    }

    if (status == 408 || status == 429 || status >= 500) {
      throw SyncRemoteException(
        SyncErrorType.temporary,
        'Backend tạm thời không xử lý được: HTTP $status',
      );
    }

    if (status != 200 && status != 201) {
      throw SyncRemoteException(
        SyncErrorType.permanent,
        'Backend từ chối nhật ký: HTTP $status',
      );
    }

    Map<String, dynamic> data;

    try {
      data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const SyncRemoteException(
        SyncErrorType.temporary,
        'Response không phải JSON hợp lệ',
      );
    }

    final id = data['id'];
    final receivedId = data['clientLogId'];
    final receivedAt = data['serverReceivedAt'];

    if (id is! int ||
        id <= 0 ||
        receivedId is! String ||
        receivedId != log.localId ||
        receivedAt is! String ||
        receivedAt.isEmpty) {
      throw const SyncRemoteException(
        SyncErrorType.permanent,
        'Response không khớp nhật ký đã gửi',
      );
    }

    if (data['farmerUserId'] != log.userId ||
        data['organizationId'] != log.organizationId ||
        data['plotId'] != log.plotId) {
      throw const SyncRemoteException(
        SyncErrorType.permanent,
        'Backend xác nhận sai chủ sở hữu hoặc Plot',
      );
    }

    return FarmingLogAck(
      serverId: id,
      clientLogId: receivedId,
      serverReceivedAt: receivedAt,
    );
  }
}
