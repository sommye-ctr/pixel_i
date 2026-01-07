import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';
import 'error_interceptor.dart';

class ApiClient {
  final String baseUrl;
  final Dio _dio;
  final TokenStorage tokenStorage;

  ApiClient({required this.baseUrl, required this.tokenStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            Headers.contentTypeHeader: Headers.jsonContentType,
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      ) {
    // Add interceptors in order: Auth → Refresh Token → Error handling
    _dio.interceptors.addAll([
      AuthInterceptor(tokenStorage),
      RefreshTokenInterceptor(
        tokenStorage: tokenStorage,
        dio: _dio,
        baseUrl: baseUrl,
      ),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
