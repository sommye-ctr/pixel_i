import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorage tokenStorage;

  AuthRepository(this.api, this.tokenStorage);

  Future<void> signup({
    required String email,
    required String name,
    required String password,
    required String username,
  }) async {
    await api.post(
      '/auth/signup/',
      data: {
        'email': email,
        'name': name,
        'password': password,
        'username': username,
      },
    );
  }

  Future<User> verifyEmail(String email, String otp) async {
    final res = await api.post<Map<String, dynamic>>(
      '/auth/verify-email/',
      data: {'email': email, 'otp': otp},
    );
    final data = res.data ?? {};

    // Extract and store JWT tokens
    final accessToken = data['access'] as String?;
    final refreshToken = data['refresh'] as String?;

    if (accessToken != null && refreshToken != null) {
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    final profile = await api.get<Map<String, dynamic>>('/auth/me/');
    final profileData = profile.data ?? {};

    return User.fromMap(profileData);
  }

  Future<User> updateProfile({
    String? bio,
    String? batch,
    String? department,
  }) async {
    final res = await api.put<Map<String, dynamic>>(
      '/auth/me/',
      data: {
        if (bio != null) 'bio': bio,
        if (batch != null) 'batch': batch,
        if (department != null) 'department': department,
      },
    );
    final data = res.data ?? {};
    return User.fromMap(data);
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}
