import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';

class ApiClient {
  final String baseUrl;
  final Dio _dio;
  final TokenStorage tokenStorage;

  ApiClient({required this.baseUrl, required this.tokenStorage})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(tokenStorage),
      RefreshTokenInterceptor(
        tokenStorage: tokenStorage,
        dio: _dio,
        baseUrl: baseUrl,
      ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
