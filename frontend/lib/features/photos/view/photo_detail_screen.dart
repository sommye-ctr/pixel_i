import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/resources/style.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<PhotoDetailBloc>().add(PhotoDetailRequested(widget.photoId));
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PhotoDetailBloc, PhotoDetailState>(
        builder: (context, state) {
          String imageUrl = widget.thumbnailUrl ?? '';

          if (state is PhotoDetailLoadSuccess &&
              state.photo.id == widget.photoId) {
            imageUrl = state.photo.originalUrl ?? state.photo.thumbnailUrl;
          } else if (state is PhotoDetailLoadFailure &&
              widget.thumbnailUrl != null) {
            imageUrl = widget.thumbnailUrl!;
          }

          if (state is PhotoDetailLoadFailure && widget.thumbnailUrl == null) {
            return Center(
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
            );
          }

          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: widget.heroTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => widget.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.thumbnailUrl!,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
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
