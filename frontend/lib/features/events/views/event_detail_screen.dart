import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String title;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.title,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Photo> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final jsonStr = await rootBundle.loadString('assets/json/photos.json');
      final List<dynamic> data = json.decode(jsonStr);
      final photos = data.map((e) => Photo.fromMap(e)).toList();

      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openPhoto(Photo photo) {
    context.push(
      '/photo/${photo.id}?heroTag=event-photo-${photo.id}&thumbnailUrl=${Uri.encodeComponent(photo.thumbnailUrl)}',
    );
  }

  Widget _buildTile(Photo photo) {
    final aspect =
        (photo.width != null && photo.height != null && photo.height != 0)
        ? photo.width! / photo.height!
        : 1.0;

    return GestureDetector(
      onTap: () => _openPhoto(photo),
      child: AspectRatio(
        aspectRatio: aspect,
        child: Hero(
          tag: 'event-photo-${photo.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: photo.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                ),
                Positioned(
                  left: defaultSpacing / 2,
                  top: defaultSpacing / 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultSpacing,
                          vertical: defaultSpacing / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(
                            smallRoundEdgeRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              photo.isLiked == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: photo.isLiked == true
                                  ? Colors.redAccent
                                  : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: defaultSpacing / 2),
                            Text(
                              photo.photographer.name.isNotEmpty
                                  ? photo.photographer.name
                                  : photo.photographer.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: defaultSpacing),
            Text(_error ?? 'Unknown error'),
            const SizedBox(height: defaultSpacing),
            ElevatedButton(onPressed: _loadPhotos, child: const Text('Retry')),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(defaultSpacing),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: defaultSpacing,
          crossAxisSpacing: defaultSpacing,
          itemCount: _photos.length,
          itemBuilder: (context, index) => _buildTile(_photos[index]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}
