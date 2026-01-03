import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/photos/bloc/photo_upload_bloc.dart';
import 'package:frontend/features/photos/bloc/photo_upload_event.dart';
import 'package:frontend/features/photos/bloc/photo_upload_state.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:frontend/features/photos/data/photos_repository.dart';
import 'package:frontend/features/photos/widgets/photo_image_tags_sheet.dart';
import 'package:frontend/features/photos/widgets/photo_permission_sheet.dart';
import 'package:frontend/features/photos/widgets/photo_tag_users_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PhotoUploadScreen extends StatefulWidget {
  final List<PlatformFile>? initialFiles;
  final String? eventId;
  final String? eventName;

  const PhotoUploadScreen({
    super.key,
    this.initialFiles,
    this.eventId,
    this.eventName,
  });

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  bool _isCarouselView = true;

  Widget _buildPickedImage(PlatformFile file) {
    Widget imageWidget;
    if (file.bytes != null) {
      imageWidget = Image.memory(file.bytes!, fit: BoxFit.cover);
    } else if (file.path != null) {
      imageWidget = Image.file(File(file.path!), fit: BoxFit.cover);
    } else {
      return const Icon(Icons.image_not_supported, size: 48);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
      child: SizedBox(height: context.heightPercent(45), child: imageWidget),
    );
  }

  Widget _buildIconActionButton(
    IconData icon,
    Color color,
    Color? iconColor,
    VoidCallback onPressed,
  ) {
    return ClipOval(
      child: Container(
        decoration: BoxDecoration(color: color),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildBlurCard({
    required String title,
    required Icon icon,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(defaultSpacing),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icon,
                    SizedBox(width: defaultSpacing / 2),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: defaultSpacing / 2),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasFiles, PhotoUploadState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.eventName ?? photoUploadTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasFiles)
                Text(
                  '${state.files.length} $eventFilesLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
            ],
          ),
        ),
        _buildIconActionButton(
          LucideIcons.layoutGrid,
          !_isCarouselView ? Colors.white : Colors.transparent,
          !_isCarouselView ? Colors.black : null,
          () {
            ToastUtils.showShort(optionsAll);
            setState(() => _isCarouselView = false);
          },
        ),
        const SizedBox(width: defaultSpacing / 2),
        _buildIconActionButton(
          LucideIcons.galleryHorizontal,
          _isCarouselView ? Colors.white : Colors.transparent,
          _isCarouselView ? Colors.black : null,
          () {
            ToastUtils.showShort(optionsPerImage);
            setState(() => _isCarouselView = true);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoOptions(BuildContext context, PhotoUploadState state) {
    final metadata = state.selectedMetadata;
    final readPermLabel = metadata?.readPerm ?? PhotoReadPermission.pub;
    final sharePermLabel = metadata?.sharePerm ?? PhotoSharePermission.anyone;
    final taggedUsers = metadata?.taggedUsernames ?? const [];
    final imageTags = metadata?.userTags ?? const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultSpacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBlurCard(
                  title: photoUploadReadPermission,
                  icon: Icon(LucideIcons.shield),
                  onTap: () => showPermissionSheet<PhotoReadPermission>(
                    context: context,
                    title: photoUploadSelectReadPermission,
                    values: PhotoReadPermission.values,
                    selected: readPermLabel,
                    onSelected: (option) => context.read<PhotoUploadBloc>().add(
                      PhotoUploadMetadataUpdated(
                        index: state.currentIndex,
                        readPerm: option,
                        applyToAll: !_isCarouselView,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: defaultSpacing / 2),
                      Expanded(
                        child: Text(
                          readPermLabel.label,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: defaultSpacing),
              Expanded(
                child: _buildBlurCard(
                  title: photoUploadSharePermission,
                  icon: Icon(LucideIcons.share2),
                  onTap: () => showPermissionSheet<PhotoSharePermission>(
                    context: context,
                    title: photoUploadSelectSharePermission,
                    values: PhotoSharePermission.values,
                    selected: sharePermLabel,
                    onSelected: (option) => context.read<PhotoUploadBloc>().add(
                      PhotoUploadMetadataUpdated(
                        index: state.currentIndex,
                        sharePerm: option,
                        applyToAll: !_isCarouselView,
                      ),
                    ),
                  ),
                  child: Text(
                    sharePermLabel.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultSpacing),
          _buildBlurCard(
            title: photoUploadTagUsers,
            icon: Icon(LucideIcons.userPen),
            onTap: () => showTagUsersSheet(
              context: context,
              authRepository: context.read<AuthRepository>(),
              initialUsernames: taggedUsers,
              onSubmit: (usernames) => context.read<PhotoUploadBloc>().add(
                PhotoUploadMetadataUpdated(
                  index: state.currentIndex,
                  taggedUsernames: usernames,
                  applyToAll: !_isCarouselView,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    taggedUsers.isEmpty
                        ? photoUploadNoTaggedUsers
                        : taggedUsers.join(', '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: defaultSpacing),
          _buildBlurCard(
            title: photoUploadImageTags,
            icon: Icon(LucideIcons.hash),
            onTap: () => showImageTagsSheet(
              context: context,
              initialTags: imageTags,
              onSubmit: (tags) => context.read<PhotoUploadBloc>().add(
                PhotoUploadMetadataUpdated(
                  index: state.currentIndex,
                  userTags: tags,
                  applyToAll: !_isCarouselView,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    imageTags.isEmpty
                        ? photoUploadNoTags
                        : imageTags.join(', '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, PhotoUploadState state) {
    return Container(
      constraints: BoxConstraints(maxHeight: context.heightPercent(45)),
      child: PageView.builder(
        itemCount: state.files.length,
        controller: _pageController,
        onPageChanged: (index) =>
            context.read<PhotoUploadBloc>().add(PhotoUploadPageChanged(index)),
        itemBuilder: (context, index) {
          final file = state.files[index];
          return Padding(
            padding: const EdgeInsets.only(right: defaultSpacing),
            child: _buildPickedImage(file),
          );
        },
      ),
    );
  }

  Widget _buildGrid(PhotoUploadState state) {
    return Container(
      constraints: BoxConstraints(maxHeight: context.heightPercent(45)),
      margin: EdgeInsets.symmetric(horizontal: defaultSpacing),
      child: GridView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: defaultSpacing,
          mainAxisSpacing: defaultSpacing,
          childAspectRatio: 1,
        ),
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          return _buildPickedImage(file);
        },
      ),
    );
  }

  String? _formatError(Map<String, dynamic>? error) {
    if (error == null || error.isEmpty) return null;
    final parts = <String>[];
    error.forEach((key, value) {
      if (value is List) {
        parts.add('$key: ${value.join(', ')}');
      } else {
        parts.add('$key: $value');
      }
    });
    return parts.join(' | ');
  }

  Widget _buildUploadResults(PhotoUploadState state) {
    if (state.files.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                photoUploadUploadResults,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.isUploading) ...[
                const SizedBox(width: defaultSpacing / 2),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: defaultSpacing / 2),
          ...state.metadata.map((meta) {
            final result = state.uploadResults[meta.clientId];
            final isSuccess = result?.isSuccess ?? false;
            final progress = state.uploadProgress[meta.clientId];
            final statusLabel = result == null
                ? state.isUploading && progress != null
                      ? '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%'
                      : photoUploadPendingStatus
                : isSuccess
                ? photoUploadSuccessStatus
                : photoUploadErrorStatus;
            final errorText = _formatError(result?.error);

            final color = result == null
                ? state.isUploading
                      ? Colors.blue.withOpacity(0.14)
                      : Colors.white.withOpacity(0.12)
                : isSuccess
                ? Colors.green.withOpacity(0.18)
                : Colors.red.withOpacity(0.18);
            final icon = result == null
                ? Icons.hourglass_bottom
                : isSuccess
                ? Icons.check_circle
                : Icons.error;

            return Container(
              margin: const EdgeInsets.only(bottom: defaultSpacing / 2),
              padding: const EdgeInsets.all(defaultSpacing / 1.2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: defaultSpacing / 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.clientId,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            errorText,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialFiles ?? const [];

    return BlocProvider(
      create: (context) =>
          PhotoUploadBloc(photosRepository: context.read<PhotosRepository>())
            ..add(PhotoUploadHydrate(initial)),
      child: BlocConsumer<PhotoUploadBloc, PhotoUploadState>(
        listenWhen: (previous, current) =>
            previous.isUploading != current.isUploading ||
            previous.uploadResults != current.uploadResults ||
            previous.uploadError != current.uploadError ||
            previous.uploadProgress != current.uploadProgress,
        listener: (context, state) {
          if (state.isUploading) return;
          if (state.uploadError != null) {
            ToastUtils.showLong('$photoUploadFailedPrefix${state.uploadError}');
            return;
          }

          if (state.uploadResults.isNotEmpty) {
            final successCount = state.uploadResults.values
                .where((r) => r.isSuccess)
                .length;
            ToastUtils.showShort(
              'Uploaded $successCount/${state.files.length} images',
            );
          }
        },
        builder: (context, state) {
          final hasFiles = state.files.isNotEmpty;

          return Scaffold(
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultSpacing,
                        ),
                        child: _buildHeader(hasFiles, state),
                      ),
                      SizedBox(height: largeSpacing * 3),
                      _isCarouselView
                          ? _buildCarousel(context, state)
                          : _buildGrid(state),
                      const SizedBox(height: largeSpacing * 2),
                      _buildPhotoOptions(context, state),
                      const SizedBox(height: largeSpacing),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultSpacing,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            onPressed: (!hasFiles || state.isUploading)
                                ? null
                                : () {
                                    final eventId = widget.eventId;
                                    if (eventId == null || eventId.isEmpty) {
                                      ToastUtils.showShort(
                                        photoUploadMissingEventId,
                                      );
                                      return;
                                    }
                                    context.read<PhotoUploadBloc>().add(
                                      PhotoUploadSubmitted(eventId),
                                    );
                                  },
                            type: RoundedButtonType.filled,
                            child: Text(
                              state.isUploading
                                  ? photoUploadUploading
                                  : photoUploadSubmit,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultSpacing),
                      _buildUploadResults(state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
