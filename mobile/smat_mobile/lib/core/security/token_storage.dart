import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  final String token;
  final int userId;
  final String username;
  Session(this.token, this.userId, this.username);
  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'username': username,
  };
  factory Session.fromJson(Map<String, dynamic> j) => Session(
    j['token'] as String,
    j['userId'] as int,
    j['username'] as String,
  );
}

class TokenStorage {
  final FlutterSecureStorage storage;
  TokenStorage({this.storage = const FlutterSecureStorage()});
  Future<Session?> read() async {
    final value = await storage.read(key: 'smat_session_v1');
    if (value == null) return null;
    try {
      return Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(Session s) =>
      storage.write(key: 'smat_session_v1', value: jsonEncode(s.toJson()));
  Future<void> clear() => storage.delete(key: 'smat_session_v1');
}
