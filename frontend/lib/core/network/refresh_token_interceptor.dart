import 'package:dio/dio.dart';
import 'token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final String baseUrl;

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

      if (refreshToken == null) {
        handler.reject(err);
        return;
      }

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
        handler.reject(err);
        return;
      }
    }

    handler.reject(err);
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
