import 'package:dio/dio.dart';
import 'token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final String baseUrl;
  final Set<String> _refreshingRequests = {}; // Track requests being refreshed

  RefreshTokenInterceptor({
    required this.tokenStorage,
    required this.dio,
    required this.baseUrl,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await tokenStorage.getRefreshToken();

      // No refresh token available, can't retry
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      // Check if this is truly a token expiration issue vs authentication failure
      if (!_isTokenExpiredError(err)) {
        handler.next(err);
        return;
      }

      final requestKey = _getRequestKey(err.requestOptions);

      if (_refreshingRequests.contains(requestKey)) {
        handler.next(err);
        return;
      }
      _refreshingRequests.add(requestKey);

      try {
        final response = await _refreshAccessToken(refreshToken);

        final newAccessToken = response.data['access'] as String?;
        if (newAccessToken != null) {
          await tokenStorage.updateAccessToken(newAccessToken);

          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(options);
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        await tokenStorage.clearTokens();
        handler.next(err);
        return;
      } finally {
        _refreshingRequests.remove(requestKey);
      }
    }

    handler.next(err);
  }

  bool _isTokenExpiredError(DioException err) {
    final data = err.response?.data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'] as String?;
      if (detail != null) {
        if (detail.contains('expired') ||
            detail.contains('Expired') ||
            detail.contains('token_not_valid')) {
          return true;
        }
        if (detail.contains('Invalid') ||
            detail.contains('invalid') ||
            detail.contains('credentials') ||
            detail.contains('Credentials')) {
          return false;
        }
      }
    }
    return true;
  }

  String _getRequestKey(RequestOptions options) {
    return '${options.method}:${options.path}';
  }

  Future<Response> _refreshAccessToken(String refreshToken) async {
    // Create a new Dio instance without interceptors to avoid infinite loop
    final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

    return await refreshDio.post(
      '/auth/token/refresh/',
      data: {'refresh': refreshToken},
    );
  }
}
