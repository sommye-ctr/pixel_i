import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:palette_generator/palette_generator.dart';

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_dominantColor, _accentColor],
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
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(
                        smallRoundEdgeRadius,
                      ),
                      child: Hero(
                        tag: widget.heroTag,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
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
                              CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  photo?.photographer.profilePicture ?? '',
                                ),
                              ),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  largeRoundEdgeRadius,
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        largeRoundEdgeRadius,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        LucideIcons.heart,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  largeRoundEdgeRadius,
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        largeRoundEdgeRadius,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        LucideIcons.share2,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
