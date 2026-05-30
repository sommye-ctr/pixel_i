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
  bool _loading = true;
  String? _error;
  List<Photo> _photos = [];
  
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  String? _nextUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPhotos();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePhotos();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final page = await widget.photosRepository.fetchTaggedInPhotos();
      if (mounted) {
        setState(() {
          _photos = page.results;
          _nextUrl = page.next;
          _hasReachedMax = page.next == null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_hasReachedMax || _isLoadingMore || _nextUrl == null) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final page = await widget.photosRepository.fetchTaggedInPhotos(url: _nextUrl);
      if (mounted) {
        setState(() {
          _photos.addAll(page.results);
          _nextUrl = page.next;
          _hasReachedMax = page.next == null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
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
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$photosTaggedInFailedPrefix$_error'),
            const SizedBox(height: defaultSpacing),
            ElevatedButton.icon(
              onPressed: _loadPhotos,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text(photosRetry),
            ),
          ],
        ),
      );
    } else if (_photos.isEmpty) {
      body = Center(
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
    } else {
      body = ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(defaultSpacing),
        children: [
          _buildPhotoMasonry(_photos),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(photosTaggedIn),
      ),
      body: body,
    );
  }
}
