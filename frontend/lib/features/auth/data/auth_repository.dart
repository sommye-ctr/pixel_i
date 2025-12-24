import '../../../core/network/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<void> requestOtp(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<User> verifyOtp(String email, String otp) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return User(id: 'u-1', name: 'Demo User');
  }

  Future<User> loginWithOAuth(String providerToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return User(id: 'u-1', name: 'Demo User');
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
