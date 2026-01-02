import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/features/photos/bloc/photo_upload_bloc.dart';
import 'package:frontend/features/photos/bloc/photo_upload_event.dart';
import 'package:frontend/features/photos/bloc/photo_upload_state.dart';
import 'package:frontend/features/photos/models/photo.dart';
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

  Future<void> _showSettingsBottomSheet<T>(
    BuildContext context,
    PhotoUploadState state,
    String title,
    List<T> values,
    Function(T option) callback,
  ) async {
    final meta = state.selectedMetadata;
    if (meta == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(largeRoundEdgeRadius),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(defaultSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: defaultSpacing),
              Wrap(
                spacing: defaultSpacing / 2,
                runSpacing: defaultSpacing / 2,
                children: [
                  for (final option in values)
                    ChoiceChip(
                      label: Text(option.toString()),
                      selected: option == meta.sharePerm,
                      onSelected: (_) {
                        callback.call(option);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImageTagsSheet(
    BuildContext context,
    PhotoUploadState state,
    Function(List<String> tags) callback,
  ) async {
    final meta = state.selectedMetadata;
    if (meta == null) return;

    final controller = TextEditingController();
    final tags = [...meta.userTags];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(largeRoundEdgeRadius),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: defaultSpacing,
            right: defaultSpacing,
            top: defaultSpacing,
            bottom: ScreenUtils.safeBottom(sheetContext) + defaultSpacing,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              void addTag() {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                if (!tags.contains(text)) {
                  setSheetState(() => tags.add(text));
                }
                controller.clear();
              }

              void removeTag(String tag) {
                setSheetState(() => tags.remove(tag));
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Image Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultSpacing),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => addTag(),
                    decoration: InputDecoration(
                      labelText: 'Tag',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addTag,
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultSpacing),
                  Wrap(
                    spacing: defaultSpacing / 2,
                    runSpacing: defaultSpacing / 2,
                    children: tags.isEmpty
                        ? [
                            Text(
                              'No tags yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ]
                        : tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () => removeTag(tag),
                                ),
                              )
                              .toList(),
                  ),
                  const SizedBox(height: defaultSpacing * 1.5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        callback(List<String>.from(tags));
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
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
          () => setState(() => _isCarouselView = false),
        ),
        const SizedBox(width: defaultSpacing / 2),
        _buildIconActionButton(
          LucideIcons.galleryHorizontal,
          _isCarouselView ? Colors.white : Colors.transparent,
          _isCarouselView ? Colors.black : null,
          () => setState(() => _isCarouselView = true),
        ),
      ],
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
      create: (_) => PhotoUploadBloc()..add(PhotoUploadHydrate(initial)),
      child: BlocBuilder<PhotoUploadBloc, PhotoUploadState>(
        builder: (context, state) {
          final hasFiles = state.files.isNotEmpty;
          final metadata = state.selectedMetadata;
          final readPermLabel = metadata?.readPerm ?? PhotoReadPermission.pub;
          final sharePermLabel =
              metadata?.sharePerm ?? PhotoSharePermission.anyone;
          final taggedUsers = metadata?.taggedUsernames ?? const [];
          final imageTags = metadata?.userTags ?? const [];

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
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: context.heightPercent(45),
                        ),
                        child: PageView.builder(
                          itemCount: state.files.length,
                          controller: _pageController,
                          onPageChanged: (index) => context
                              .read<PhotoUploadBloc>()
                              .add(PhotoUploadPageChanged(index)),
                          itemBuilder: (context, index) {
                            final file = state.files[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: defaultSpacing,
                              ),
                              child: _buildPickedImage(file),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: largeSpacing * 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultSpacing,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBlurCard(
                                    title: 'Read Permission',
                                    icon: Icon(LucideIcons.shield),
                                    onTap: () => _showSettingsBottomSheet(
                                      context,
                                      state,
                                      "Select read permission",
                                      PhotoReadPermission.values,
                                      (option) =>
                                          context.read<PhotoUploadBloc>().add(
                                            PhotoUploadMetadataUpdated(
                                              index: state.currentIndex,
                                              readPerm: option,
                                            ),
                                          ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: defaultSpacing / 2,
                                        ),
                                        Expanded(
                                          child: Text(
                                            readPermLabel.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: defaultSpacing),
                                Expanded(
                                  child: _buildBlurCard(
                                    title: 'Share Permission',
                                    icon: Icon(LucideIcons.share2),
                                    onTap: () => _showSettingsBottomSheet(
                                      context,
                                      state,
                                      "Select share permission",
                                      PhotoSharePermission.values,
                                      (option) =>
                                          context.read<PhotoUploadBloc>().add(
                                            PhotoUploadMetadataUpdated(
                                              index: state.currentIndex,
                                              sharePerm: option,
                                            ),
                                          ),
                                    ),
                                    child: Text(
                                      sharePermLabel.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultSpacing),
                            _buildBlurCard(
                              title: 'Tag Users',
                              icon: Icon(LucideIcons.userPen),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      taggedUsers.isEmpty
                                          ? 'No tagged users'
                                          : taggedUsers.join(', '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                            const SizedBox(height: defaultSpacing),
                            _buildBlurCard(
                              title: 'Image Tags',
                              icon: Icon(LucideIcons.hash),
                              onTap: () =>
                                  _showImageTagsSheet(context, state, (tags) {
                                    context.read<PhotoUploadBloc>().add(
                                      PhotoUploadMetadataUpdated(
                                        index: state.currentIndex,
                                        userTags: tags,
                                      ),
                                    );
                                  }),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      imageTags.isEmpty
                                          ? 'No tags added'
                                          : imageTags.join(', '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
