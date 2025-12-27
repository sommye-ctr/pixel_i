import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final Map<String, dynamic>? errorData;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
    this.errorData,
  });

  @override
  String toString() => message;
}

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final message = _extractErrorMessage(err);
    final statusCode = err.response?.statusCode;
    final errorData = err.response?.data;

    final apiException = ApiException(
      message: message,
      statusCode: statusCode,
      originalError: err,
      errorData: errorData is Map ? errorData as Map<String, dynamic> : null,
    );

    handler.reject(err.copyWith(error: apiException, message: message));
  }

  String _extractErrorMessage(DioException err) {
    // No response from server
    if (err.response == null) {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.sendTimeout:
          return 'Request timeout. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond. Please try again.';
        case DioExceptionType.badResponse:
          return 'Bad response from server';
        case DioExceptionType.cancel:
          return 'Request was cancelled';
        case DioExceptionType.unknown:
        default:
          return err.message ?? 'An unexpected error occurred';
      }
    }

    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    if (data is Map<String, dynamic>) {
      // Django non-field errors: {"non_field_errors": ["error message"]}
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
      }

      // Django field-specific errors: {"email": ["Invalid email"], "username": ["Already exists"]}
      if (_containsFieldErrors(data)) {
        return _extractFieldErrors(data);
      }

      // Django REST detail: {"detail": "error message"}
      if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) return detail;
      }
    }

    // HTTP status code messages
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return data is String
              ? data
              : 'Bad request. Please check your input.';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access denied.';
        case 404:
          return 'Resource not found.';
        case 409:
          return 'Conflict. This resource already exists.';
        case 422:
          return 'Validation error. Please check your input.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
          return 'Bad gateway. Please try again later.';
        case 503:
          return 'Service unavailable. Please try again later.';
        default:
          return 'Error: ${err.response?.statusMessage}';
      }
    }

    return err.message ?? 'An unexpected error occurred';
  }

  bool _containsFieldErrors(Map<String, dynamic> data) {
    return data.values.any(
      (value) => value is List && value.isNotEmpty && value.first is String,
    );
  }

  String _extractFieldErrors(Map<String, dynamic> data) {
    final errors = <String>[];

    data.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        final firstError = value.first;
        errors.add('$key: $firstError');
      }
    });

    return errors.join('\n');
  }
}
