import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/utils/photo_utils.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/features/photos/bloc/photos_bloc.dart';
import 'package:frontend/features/photos/bloc/photos_event.dart';
import 'package:frontend/features/photos/data/photos_repository.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:frontend/features/photos/widgets/photo_tagged_users_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/widgets/animated_heart.dart';
import 'package:frontend/core/widgets/user_avatar.dart';
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
  late final PageController _pageController;
  Color _dominantColor = Colors.black;
  Color _accentColor = Colors.grey;
  List<Photo> _photos = [];
  int _currentIndex = 0;

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
    final repo = context.read<PhotosRepository>();
    _photos = List<Photo>.from(repo.cachedPhotos ?? const []);
    _currentIndex = _photos.indexWhere((p) => p.id == widget.photoId);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);

    context.read<PhotoDetailBloc>().add(PhotoDetailRequested(widget.photoId));
    final thumb =
        widget.thumbnailUrl ??
        (_photos.isNotEmpty ? _photos.first.thumbnailUrl : null);
    if (thumb != null) {
      _extractColors(thumb);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Photo? _photoFromState(PhotoDetailState state, String photoId) {
    if (state is PhotoDetailLoadSuccess && state.photo.id == photoId) {
      return state.photo;
    }
    if (state is PhotoLikeSuccess && state.photo.id == photoId) {
      return state.photo;
    }
    if (state is PhotoLikeFailure && state.photo.id == photoId) {
      return state.photo;
    }
    if (state is PhotoLikeInProgress && state.photo.id == photoId) {
      return state.photo;
    }
    return null;
  }

  void _syncPhotoToLocalList(Photo photo) {
    final idx = _photos.indexWhere((p) => p.id == photo.id);
    setState(() {
      if (idx == -1) {
        _photos.insert(_currentIndex.clamp(0, _photos.length), photo);
        _currentIndex = _photos.indexWhere((p) => p.id == photo.id);
      } else {
        _photos[idx] = photo;
        _currentIndex = idx;
      }
    });
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _photos.length) return;
    final photo = _photos[index];
    setState(() => _currentIndex = index);
    _transformationController.value = Matrix4.identity();
    _extractColors(photo.thumbnailUrl);
    final repo = context.read<PhotosRepository>();
    final cached = repo.getById(photo.id);
    if (cached?.watermarkedUrl == null) {
      context.read<PhotoDetailBloc>().add(PhotoDetailRequested(photo.id));
    }
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommentsBottomSheet(),
    );
  }

  void _openTaggedUsersSheet(Photo? photo) {
    if (photo == null) return;
    showTaggedUsersSheet(
      context: context,
      users: photo.taggedUsers ?? const [],
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
                          size: 28,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.messageCircle),
                          onPressed: _openCommentsBottomSheet,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.users),
                          onPressed: () => _openTaggedUsersSheet(photo),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.download),
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
          if (photo?.canDelete == true)
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
      body: BlocListener<PhotoDetailBloc, PhotoDetailState>(
        listener: (context, state) {
          if (state is PhotoDetailLoadSuccess || state is PhotoLikeSuccess) {
            final photo = state is PhotoDetailLoadSuccess
                ? state.photo
                : (state as PhotoLikeSuccess).photo;
            _syncPhotoToLocalList(photo);
            context.read<PhotosBloc>().add(PhotoUpdated(photo));
          }
          if (state is PhotoLikeFailure) {
            ToastUtils.showLong('Error: ${state.error}');
          }
        },
        child: BlocBuilder<PhotoDetailBloc, PhotoDetailState>(
          builder: (context, state) {
            List<Photo> displayPhotos = _photos;
            if (displayPhotos.isEmpty) {
              if (state is PhotoDetailLoadSuccess) {
                displayPhotos = [state.photo];
              } else if (state is PhotoLikeSuccess) {
                displayPhotos = [state.photo];
              } else if (state is PhotoLikeFailure) {
                displayPhotos = [state.photo];
              }
            }

            final hasPhotos = displayPhotos.isNotEmpty;
            final safeIndex = hasPhotos
                ? _currentIndex.clamp(0, displayPhotos.length - 1)
                : 0;
            final baseActivePhoto = hasPhotos ? displayPhotos[safeIndex] : null;
            final activePhoto = baseActivePhoto != null
                ? _photoFromState(state, baseActivePhoto.id) ?? baseActivePhoto
                : null;

            if (state is PhotoDetailLoadFailure &&
                widget.thumbnailUrl == null &&
                !hasPhotos) {
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
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: hasPhotos ? displayPhotos.length : 1,
                    itemBuilder: (context, index) {
                      final basePhoto = hasPhotos
                          ? displayPhotos[index]
                          : activePhoto;
                      final resolvedPhoto = basePhoto != null
                          ? _photoFromState(state, basePhoto.id) ?? basePhoto
                          : null;
                      final heroTag = index == safeIndex
                          ? widget.heroTag
                          : 'photo-${resolvedPhoto?.id ?? basePhoto?.id ?? ''}';
                      final imageUrl =
                          resolvedPhoto?.watermarkedUrl ??
                          resolvedPhoto?.thumbnailUrl ??
                          widget.thumbnailUrl ??
                          '';

                      if (resolvedPhoto == null) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        panEnabled: false,
                        child: Center(
                          child: Hero(
                            tag: heroTag,
                            child: AspectRatio(
                              aspectRatio: PhotoUtils.aspectRatio(
                                resolvedPhoto,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.fitWidth,
                                placeholder: (context, url) =>
                                    CachedNetworkImage(
                                      imageUrl: resolvedPhoto.thumbnailUrl,
                                      fit: BoxFit.fitWidth,
                                    ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultSpacing / 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(LucideIcons.arrowLeft),
                                  onPressed: () => context.pop(),
                                ),
                                const SizedBox(width: defaultSpacing / 2),
                                UserAvatar(
                                  username:
                                      activePhoto?.photographer.name ?? '',
                                  profilePicture:
                                      activePhoto?.photographer.profilePicture,
                                ),
                                SizedBox(width: defaultSpacing),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activePhoto?.photographer.name ?? '',
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
                    child: _getBottomActions(activePhoto),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
