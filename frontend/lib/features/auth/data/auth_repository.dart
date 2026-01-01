import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorage tokenStorage;

  User? _currentUser;

  AuthRepository(this.api, this.tokenStorage);

  User? get currentUser => _currentUser;

  void _setCurrentUser(User user) {
    _currentUser = user;
  }

  void _clearCurrentUser() {
    _currentUser = null;
  }

  Future<User> fetchCurrentUserProfile() async {
    final profile = await api.get<Map<String, dynamic>>('/auth/me/');
    final profileData = profile.data ?? {};

    final user = User.fromMap(profileData);
    _setCurrentUser(user);
    return user;
  }

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

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final res = await api.post<Map<String, dynamic>>(
      '/auth/login/',
      data: {'username': username, 'password': password},
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

    final user = User.fromMap(profileData);
    _setCurrentUser(user);
    return user;
  }

  Future<void> requestOtp(String email) async {
    await api.post('/auth/request-otp/', data: {'email': email});
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

    final user = User.fromMap(profileData);
    _setCurrentUser(user);
    return user;
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
    final user = User.fromMap(data);
    _setCurrentUser(user);
    return user;
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
    _clearCurrentUser();
  }
}
