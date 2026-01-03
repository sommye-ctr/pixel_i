import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/utils/index.dart';
import 'package:frontend/features/events/data/events_repository.dart';
import 'package:frontend/features/photos/bloc/photo_upload_bloc.dart';
import 'package:frontend/features/photos/models/photo.dart';
import 'package:frontend/features/events/bloc/events_bloc.dart';
import 'package:frontend/features/events/bloc/events_event.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final int? fileCount;
  final DateTime? createdAt;
  final String? coverPhotoUrl;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.title,
    this.fileCount,
    this.createdAt,
    this.coverPhotoUrl,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Photo> _photos = [];

  int get _displayFileCount => widget.fileCount ?? _photos.length;

  String? get _formattedCreatedAt {
    return formatShortDate(widget.createdAt);
  }

  Widget _buildHeader() {
    final coverUrl = widget.coverPhotoUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultSpacing),
      constraints: BoxConstraints(
        minWidth: context.widthPercent(100),
        maxHeight: context.heightPercent(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) => ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade300),
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.grey.shade400),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(defaultSpacing),
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: defaultSpacing / 2),
                    Text(
                      '$_displayFileCount $eventFilesLabel • $eventCreatedLabel ${_formattedCreatedAt ?? dashPlaceholder}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

      final repository = context.read<EventsRepository>();
      final photos = await repository.fetchEventPhotos(widget.eventId);

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

  Future<void> _pickAndUpload() async {
    ToastUtils.showShort(photoUploadCardText);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    final files = result.files;
    if (files.length > PhotoUploadBloc.maxFiles) {
      ToastUtils.showShort(photoUploadTooMany);
      return;
    }

    if (!mounted) return;
    final res = await context.push(
      '/photos/upload',
      extra: {
        'files': files,
        'eventId': widget.eventId,
        'eventName': widget.title,
      },
    );

    if (mounted && res == true) {
      _loadPhotos();
      context.read<EventsBloc>().add(const EventsRefreshed());
    }
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
            Text(_error ?? unknownErrorLabel),
            const SizedBox(height: defaultSpacing),
            ElevatedButton(
              onPressed: _loadPhotos,
              child: const Text(retryLabel),
            ),
          ],
        ),
      );
    } else {
      body = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: largeSpacing),
            if (_photos.isEmpty)
              Center(
                child: Text(
                  photosNoPhotos,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(defaultSpacing),
                child: MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: defaultSpacing,
                  crossAxisSpacing: defaultSpacing,
                  itemCount: _photos.length,
                  itemBuilder: (context, index) => _buildTile(_photos[index]),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        child: const Icon(Icons.add),
      ),
    );
  }
}
