import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

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
  bool _isGrid =
      true; // toggle between grid and masonry (masonry not implemented yet)

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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(
              photo.originalUrl ?? photo.thumbnailUrl,
            ),
          ),
        ),
      ),
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
                const Text('Failed to load photos'),
                const SizedBox(height: defaultSpacing),
                Text(state.error),
                const SizedBox(height: defaultSpacing),
                ElevatedButton(
                  onPressed: () =>
                      context.read<PhotosBloc>().add(PhotosRequested()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is PhotosLoadSuccess && state.photos.isEmpty) {
          body = const Center(child: Text('No photos yet'));
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
                  _isGrid
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final photo = items[i];
                            return GestureDetector(
                              onTap: () => _openPhoto(photo),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  smallRoundEdgeRadius,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: photo.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey.shade200),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.layoutGrid,
                                size: 32,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              const Text('Masonry view coming soon'),
                            ],
                          ),
                        ),
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
                tooltip: _isGrid ? 'Grid view' : 'Masonry view',
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
