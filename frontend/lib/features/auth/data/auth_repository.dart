import '../../../core/network/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<void> signup({
    required String email,
    required String name,
    required String password,
    required String username,
  }) async {
    // Replace path/body with your backend contract
    await api.post('/auth/signup', data: {
      'email': email,
      'name': name,
      'password': password,
      'username': username,
    });
  }

  Future<void> requestOtp(String email) async {
    await api.post('/auth/request-otp', data: {
      'email': email,
    });
  }

  Future<User> verifyOtp(String email, String otp) async {
    final res = await api.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {
        'email': email,
        'otp': otp,
      },
    );
    final data = res.data ?? {};
    return User(
      id: (data['id'] ?? 'u-1').toString(),
      name: (data['name'] ?? 'User').toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      batch: data['batch']?.toString(),
      department: data['department']?.toString(),
    );
  }

  Future<User> loginWithOAuth(String providerToken) async {
    final res = await api.post<Map<String, dynamic>>(
      '/auth/oauth',
      data: {
        'token': providerToken,
      },
    );
    final data = res.data ?? {};
    return User(
      id: (data['id'] ?? 'u-1').toString(),
      name: (data['name'] ?? 'User').toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      batch: data['batch']?.toString(),
      department: data['department']?.toString(),
    );
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<User> updateProfile({
    String? bio,
    String? batch,
    String? department,
  }) async {
    final res = await api.put<Map<String, dynamic>>(
      '/user/profile',
      data: {
        if (bio != null) 'bio': bio,
        if (batch != null) 'batch': batch,
        if (department != null) 'department': department,
      },
    );
    final data = res.data ?? {};
    return User(
      id: (data['id'] ?? 'u-1').toString(),
      name: (data['name'] ?? 'User').toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      batch: data['batch']?.toString(),
      department: data['department']?.toString(),
    );
  }
}
