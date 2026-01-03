import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/widgets/animated_heart.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:frontend/features/comments/view/comments_bottom_sheet.dart';
import 'package:frontend/core/utils/toast_utils.dart';

import '../../../core/resources/strings.dart';
import '../bloc/photo_detail_bloc.dart';
import '../bloc/photo_detail_event.dart';
import '../bloc/photo_detail_state.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String photoId;
  final String heroTag;
  final String? thumbnailUrl;

  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    required this.heroTag,
    this.thumbnailUrl,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final TransformationController _transformationController =
      TransformationController();
  Color _dominantColor = Colors.black;
  Color _accentColor = Colors.grey;

  Future<void> _extractColors(String imageUrl) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
      );
      setState(() {
        _dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
        _accentColor = paletteGenerator.vibrantColor?.color ?? Colors.grey;
      });
    } catch (e) {
      setState(() {
        _dominantColor = Colors.black;
        _accentColor = Colors.grey;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<PhotoDetailBloc>().add(PhotoDetailRequested(widget.photoId));
    if (widget.thumbnailUrl != null) {
      _extractColors(widget.thumbnailUrl!);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _getUserAvatar(Photo? photo) {
    if ((photo?.photographer.profilePicture ?? '').isNotEmpty) {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(
          photo!.photographer.profilePicture!,
        ),
      );
    }
    String initial = (photo?.photographer.name ?? "?")[0];
    return CircleAvatar(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommentsBottomSheet(),
    );
  }

  Widget _getTopActionButton(Icon icon, VoidCallback onPressed) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.1),
          child: IconButton(icon: icon, onPressed: onPressed),
        ),
      ),
    );
  }

  Widget _getBottomActions(Photo? photo) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ScreenUtils.safeBottom(context),
        left: defaultSpacing,
        right: defaultSpacing,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                  height: kBottomNavigationBarHeight + 8,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AnimatedHeart(
                          isActive: photo?.isLiked ?? false,
                          onChanged: (_) {
                            if (photo != null) {
                              context.read<PhotoDetailBloc>().add(
                                PhotoLikeToggleRequested(photo),
                              );
                            }
                          },
                          activeColor: Colors.redAccent,
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.download),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.messageCircle),
                          onPressed: _openCommentsBottomSheet,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.users),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: defaultSpacing),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SizedBox.square(
                dimension: kBottomNavigationBarHeight + 8,
                child: Container(
                  color: Colors.red.withOpacity(0.8),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(LucideIcons.trash),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PhotoDetailBloc, PhotoDetailState>(
        builder: (context, state) {
          String imageUrl = widget.thumbnailUrl ?? '';
          Photo? photo;

          if (state is PhotoDetailLoadSuccess &&
              state.photo.id == widget.photoId) {
            imageUrl = state.photo.originalUrl ?? state.photo.thumbnailUrl;
            photo = state.photo;
          } else if (state is PhotoLikeSuccess &&
              state.photo.id == widget.photoId) {
            imageUrl = state.photo.originalUrl ?? state.photo.thumbnailUrl;
            photo = state.photo;
          } else if (state is PhotoLikeFailure &&
              state.photo.id == widget.photoId) {
            imageUrl = state.photo.originalUrl ?? state.photo.thumbnailUrl;
            photo = state.photo;
            ToastUtils.showLong('Error: ${state.error}');
          } else if (state is PhotoDetailLoadFailure &&
              widget.thumbnailUrl != null) {
            imageUrl = widget.thumbnailUrl!;
          }

          if (state is PhotoDetailLoadFailure && widget.thumbnailUrl == null) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_dominantColor, _accentColor],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: largeSpacing),
                    Text(
                      photosFailedToLoad,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: defaultSpacing),
                    Text(
                      state.error,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dominantColor.withOpacity(0.8),
                  _accentColor,
                  _dominantColor.withOpacity(0.8),
                ],
              ),
            ),
            width: context.widthPercent(100),
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: widget.heroTag,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.fitWidth,
                        placeholder: (context, url) =>
                            widget.thumbnailUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.thumbnailUrl!,
                                fit: BoxFit.contain,
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _getUserAvatar(photo),
                              SizedBox(width: defaultSpacing),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo?.photographer.username ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    "Event",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _getTopActionButton(
                                Icon(LucideIcons.share2),
                                () {},
                              ),
                              const SizedBox(width: defaultSpacing / 2),

                              _getTopActionButton(
                                Icon(LucideIcons.info),
                                () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _getBottomActions(photo),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
