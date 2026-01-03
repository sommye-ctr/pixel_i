import 'package:equatable/equatable.dart';

class PhotoBulkUploadResult extends Equatable {
  final String clientId;
  final String? photoId;
  final String status;
  final Map<String, dynamic>? error;

  const PhotoBulkUploadResult({
    required this.clientId,
    this.photoId,
    required this.status,
    this.error,
  });

  factory PhotoBulkUploadResult.fromMap(Map<String, dynamic> map) {
    return PhotoBulkUploadResult(
      clientId: map['client_id'] as String,
      photoId: map['photo_id'] as String?,
      status: map['status'] as String? ?? 'unknown',
      error: map['error'] == null
          ? null
          : Map<String, dynamic>.from(map['error'] as Map),
    );
  }

  bool get isSuccess => status.toLowerCase() == 'created' || photoId != null;

  @override
  List<Object?> get props => [clientId, photoId, status, error];
}
