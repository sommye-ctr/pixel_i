import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/index.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/features/photos/bloc/photo_upload_bloc.dart';
import 'package:frontend/features/photos/bloc/photo_upload_state.dart';
import 'package:frontend/features/photos/models/photo_bulk_upload_result.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PhotoUploadResultScreen extends StatelessWidget {
  const PhotoUploadResultScreen({super.key});

  Widget _buildStatusIcon(PhotoBulkUploadResult? result, bool isUploading) {
    if (isUploading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (result == null) {
      return Icon(LucideIcons.clock, color: Colors.amber, size: 24);
    }

    if (result.isSuccess) {
      return Icon(LucideIcons.check, color: Colors.green, size: 24);
    }

    return Icon(LucideIcons.x, color: Colors.red, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoUploadBloc, PhotoUploadState>(
      buildWhen: (previous, current) =>
          previous.uploadProgress != current.uploadProgress ||
          previous.uploadResults != current.uploadResults ||
          previous.isUploading != current.isUploading,
      builder: (context, state) {
        final completedCount = state.uploadProgress.values
            .where((p) => p >= 0.99)
            .length;
        final totalCount = state.files.length;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.8),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultSpacing,
                      vertical: largeSpacing,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Progress',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: defaultSpacing),
                        Text(
                          '$completedCount/$totalCount photos',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultSpacing,
                      ),
                      itemCount: state.files.length,
                      itemBuilder: (context, index) {
                        final file = state.files[index];
                        final metadata = state.metadata.length > index
                            ? state.metadata[index]
                            : null;
                        final clientId = metadata?.clientId;
                        final progress = clientId != null
                            ? state.uploadProgress[clientId] ?? 0.0
                            : 0.0;
                        final result = clientId != null
                            ? state.uploadResults[clientId]
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: defaultSpacing,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                largeRoundEdgeRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(defaultSpacing),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          smallRoundEdgeRadius,
                                        ),
                                        child: SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: file.bytes != null
                                              ? Image.memory(
                                                  file.bytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey,
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: defaultSpacing),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% • ${PhotoUtils.formatFileSize(file.size)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: defaultSpacing),
                                      _buildStatusIcon(
                                        result,
                                        state.isUploading,
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.isUploading)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      defaultSpacing,
                                      0,
                                      defaultSpacing,
                                      defaultSpacing,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 4,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(defaultSpacing),
                    child: SizedBox(
                      width: double.infinity,
                      child: state.isUploading
                          ? Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  largeRoundEdgeRadius,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CustomButton(
                              onPressed: () => Navigator.of(context).pop(),
                              type: RoundedButtonType.filled,
                              child: Text("Done"),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
