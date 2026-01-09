import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';
import '../../../core/resources/style.dart';
import '../data/photos_repository.dart';
import '../models/photo.dart';

class TaggedInPhotosScreen extends StatefulWidget {
  final PhotosRepository photosRepository;

  const TaggedInPhotosScreen({super.key, required this.photosRepository});

  @override
  State<TaggedInPhotosScreen> createState() => _TaggedInPhotosScreenState();
}

class _TaggedInPhotosScreenState extends State<TaggedInPhotosScreen> {
  late Future<List<Photo>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _photosFuture = widget.photosRepository.fetchTaggedInPhotos();
  }

  void _openPhoto(Photo photo) {
    context.push(
      '/photo/${photo.id}?heroTag=photo-${photo.id}&thumbnailUrl=${Uri.encodeComponent(photo.thumbnailUrl)}',
    );
  }

  Widget _buildPhotoTile(Photo photo) {
    final aspectRatio = photo.width != null && photo.height != null
        ? photo.width! / photo.height!
        : 1.0;
    return GestureDetector(
      onTap: () => _openPhoto(photo),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Hero(
          tag: 'photo-${photo.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
            child: CachedNetworkImage(
              imageUrl: photo.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoMasonry(List<Photo> items) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: defaultSpacing,
      crossAxisSpacing: defaultSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildPhotoTile(items[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Photo>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$photosTaggedInFailedPrefix${snapshot.error}'),
                  const SizedBox(height: defaultSpacing),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _photosFuture = widget.photosRepository
                            .fetchTaggedInPhotos();
                      });
                    },
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text(photosRetry),
                  ),
                ],
              ),
            );
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.image,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: largeSpacing),
                  Text(
                    photosTaggedInEmpty,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(defaultSpacing),
            children: [_buildPhotoMasonry(photos)],
          );
        },
      ),
    );
  }
}
