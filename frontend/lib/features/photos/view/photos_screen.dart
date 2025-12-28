import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/resources/strings.dart';
import '../models/photo.dart';
import '../bloc/photos_bloc.dart';
import '../bloc/photos_event.dart';
import '../bloc/photos_state.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotosBloc>().add(PhotosRequested());
    });
  }

  Map<String, List<Photo>> _groupByMonthYear(List<Photo> photos) {
    final Map<String, List<Photo>> map = {};
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    for (final p in photos) {
      final key = '${monthNames[p.timestamp.month - 1]} ${p.timestamp.year}';
      map.putIfAbsent(key, () => []);
      map[key]!.add(p);
    }
    return map;
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

  Widget _buildPhotoGrid(List<Photo> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: defaultSpacing,
        mainAxisSpacing: defaultSpacing,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildPhotoTile(items[i]),
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
    return BlocBuilder<PhotosBloc, PhotosState>(
      builder: (context, state) {
        Widget body;
        if (state is PhotosLoadInProgress || state is PhotosInitial) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state is PhotosLoadFailure) {
          body = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(photosFailedToLoad),
                const SizedBox(height: defaultSpacing),
                Text(state.error),
                const SizedBox(height: defaultSpacing),
                ElevatedButton(
                  onPressed: () =>
                      context.read<PhotosBloc>().add(PhotosRequested()),
                  child: const Text(photosRetry),
                ),
              ],
            ),
          );
        } else if (state is PhotosLoadSuccess && state.photos.isEmpty) {
          body = const Center(child: Text(photosNoPhotos));
        } else if (state is PhotosLoadSuccess) {
          final groups = _groupByMonthYear(state.photos);
          body = ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.keys.length,
            itemBuilder: (context, index) {
              final key = groups.keys.elementAt(index);
              final items = groups[key]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: defaultSpacing),
                  _isGrid ? _buildPhotoGrid(items) : _buildPhotoMasonry(items),
                  const SizedBox(height: largeSpacing),
                ],
              );
            },
          );
        } else {
          body = const SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              photosTitle,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGrid
                      ? LucideIcons.layoutGrid
                      : LucideIcons.layoutDashboard,
                ),
                tooltip: _isGrid ? photosGridView : photosMasonryView,
                onPressed: () => setState(() => _isGrid = !_isGrid),
              ),
              IconButton(onPressed: () {}, icon: Icon(LucideIcons.heart)),
              IconButton(onPressed: () {}, icon: Icon(LucideIcons.bell)),
            ],
          ),
          body: body,
        );
      },
    );
  }
}
