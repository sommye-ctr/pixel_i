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
import 'package:frontend/features/auth/bloc/auth_bloc.dart';
import 'package:frontend/core/widgets/custom_text_field.dart';
import 'package:frontend/features/events/models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final int? fileCount;
  final DateTime? createdAt;
  final String? coverPhotoUrl;
  final bool canWrite;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.title,
    required this.canWrite,
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

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  String? _nextUrl;

  int get _displayFileCount => widget.fileCount ?? _photos.length;

  String? get _formattedCreatedAt {
    return formatShortDate(widget.createdAt);
  }

  Widget _buildHeader() {
    final coverUrl = widget.coverPhotoUrl;
    final user = context.read<AuthBloc>().state.user;
    final repo = context.read<EventsRepository>();
    final event = repo.getEventFromCache(widget.eventId);
    final isOwner =
        event != null && user != null && event.coordinator.id == user.id;

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
                      event?.title ?? widget.title,
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
            if (isOwner)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _openEditBottomSheet,
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

      final repository = context.read<EventsRepository>();
      final page = await repository.fetchEventPhotos(widget.eventId);

      setState(() {
        _photos = page.results;
        _nextUrl = page.next;
        _hasReachedMax = page.next == null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_hasReachedMax || _isLoadingMore || _nextUrl == null) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final repository = context.read<EventsRepository>();
      final page = await repository.fetchEventPhotos(
        widget.eventId,
        url: _nextUrl,
      );
      setState(() {
        _photos.addAll(page.results);
        _nextUrl = page.next;
        _hasReachedMax = page.next == null;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
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

  void _openEditBottomSheet() async {
    final repo = context.read<EventsRepository>();
    final event = repo.getEventFromCache(widget.eventId);
    if (event == null) return;

    final titleController = TextEditingController(text: event.title);
    String selectedReadPerm = event.readPerm.value;
    bool isSaving = false;
    bool isDeleting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + defaultSpacing,
                left: defaultSpacing,
                right: defaultSpacing,
                top: largeSpacing,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: largeSpacing),
                  CustomTextField(
                    hint: 'Event Title',
                    controller: titleController,
                  ),
                  const SizedBox(height: defaultSpacing),
                  DropdownButtonFormField<String>(
                    value: selectedReadPerm,
                    decoration: const InputDecoration(
                      labelText: 'Read Permission',
                      border: OutlineInputBorder(),
                    ),
                    items: EventPermission.values.map((perm) {
                      return DropdownMenuItem(
                        value: perm.value,
                        child: Text(perm.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedReadPerm = val);
                      }
                    },
                  ),
                  const SizedBox(height: largeSpacing * 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isDeleting || isSaving
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete Event?'),
                                      content: const Text(
                                        'This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setModalState(() => isDeleting = true);
                                    try {
                                      await repo.deleteEvent(event.id);
                                      if (mounted) {
                                        context.read<EventsBloc>().add(
                                          const EventsRefreshed(),
                                        );
                                        Navigator.pop(ctx);
                                        context.pop();
                                        ToastUtils.showShort('Event deleted');
                                      }
                                    } catch (e) {
                                      ToastUtils.showShort(
                                        'Failed to delete event',
                                      );
                                    } finally {
                                      setModalState(() => isDeleting = false);
                                    }
                                  }
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Text('Delete Event'),
                        ),
                      ),
                      const SizedBox(width: defaultSpacing),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving || isDeleting
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  try {
                                    await repo.updateEvent(
                                      eventId: event.id,
                                      title: titleController.text.trim(),
                                      readPerm: selectedReadPerm,
                                    );
                                    if (mounted) {
                                      context.read<EventsBloc>().add(
                                        const EventsRefreshed(),
                                      );
                                      setState(
                                        () {},
                                      ); // Refresh detail screen UI
                                      Navigator.pop(ctx);
                                      ToastUtils.showShort('Event updated');
                                    }
                                  } catch (e) {
                                    ToastUtils.showShort(
                                      'Failed to update event',
                                    );
                                  } finally {
                                    setModalState(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
        controller: _scrollController,
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
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: body),
      floatingActionButton: widget.canWrite
          ? FloatingActionButton(
              onPressed: _pickAndUpload,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
