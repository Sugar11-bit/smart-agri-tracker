import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiFailure implements Exception {
  final int status;
  ApiFailure(this.status);
}

class ApiClient {
  final http.Client client;
  final String baseUrl;
  ApiClient({http.Client? client, this.baseUrl = ApiConfig.baseUrl})
    : client = client ?? http.Client();
  Future<dynamic> request(
    String path, {
    String? token,
    Map<String, String>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response =
        await (body == null
                ? client.get(uri, headers: headers)
                : client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(ApiConfig.requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiFailure(response.statusCode);
    }
    return jsonDecode(response.body);
  }
}
