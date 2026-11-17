import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorage storage;
  AuthRepository(this.api, this.storage);
  Future<Session> login(String username, String password) async {
    // Do not persist a token until /me has verified its owner.
    final login = await api.request(
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
    );
    final token = login['accessToken'] as String;
    final me = await api.request('/api/v1/auth/me', token: token);
    final session = Session(
      token,
      me['userId'] as int,
      me['username'] as String,
    );
    await storage.save(session);
    return session;
  }
}
