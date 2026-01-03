import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:uuid/uuid.dart';

class PhotoUtils {
  static const _uuid = Uuid();

  static String generateClientId() => _uuid.v4();

  static String getFileExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filename.substring(lastDot);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Map<String, double> progressByFile(
    int sentBytes,
    List<PlatformFile> files,
  ) {
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.size);
    if (totalBytes <= 0) return const <String, double>{};

    final progress = <String, double>{};
    var cursor = 0;
    for (final file in files) {
      final size = file.size;
      if (size <= 0) {
        progress[file.name] = 0;
        continue;
      }
      final start = cursor;
      final end = cursor + size;
      final fraction = ((sentBytes - start) / size).clamp(0.0, 1.0);
      progress[file.name] = fraction;
      cursor = end;
    }
    return progress;
  }

  static double aspectRatio(Photo? photo, {double fallback = 1.0}) {
    final width = photo?.width ?? 0;
    final height = photo?.height ?? 0;
    if (width > 0 && height > 0) {
      return width / height;
    }
    return fallback;
  }
}
