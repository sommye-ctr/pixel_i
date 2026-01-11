import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/widgets/custom_text_field.dart';

import '../../photos/models/photo.dart';
import '../data/search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _tagsController = TextEditingController();
  final _photographerController = TextEditingController();
  final _eventController = TextEditingController();

  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  DateTime? _selectedFrom;
  DateTime? _selectedTo;

  bool _moreFiltersApplied = false;

  bool _loading = false;
  List<Photo> _photos = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _photographerController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  DateTime? _dateFrom() => _selectedFrom;
  DateTime? _dateTo() => _selectedTo;

  Future<void> _performSearch(SearchRepository repo) async {
    setState(() => _loading = true);
    try {
      final tags = _tagsController.text
          .split(' ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final results = await repo.searchPhotos(
        dateFrom: _dateFrom(),
        dateTo: _dateTo(),
        photographerName: _photographerController.text.trim().isEmpty
            ? null
            : _photographerController.text.trim(),
        eventName: _eventController.text.trim().isEmpty
            ? null
            : _eventController.text.trim(),
        tags: tags.isEmpty ? null : tags,
      );

      setState(() {
        _photos = results;
      });
    } catch (e) {
      setState(() {
        _photos = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openPhoto(Photo photo) {
    context.push(
      '/photo/${photo.id}?heroTag=photo-${photo.id}&thumbnailUrl=${Uri.encodeComponent(photo.thumbnailUrl)}',
    );
  }

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? initial) async {
    final now = DateTime.now();
    final first = DateTime(2000);
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial ?? now,
      firstDate: first,
      lastDate: now,
    );
    return picked;
  }

  void _openMoreFilters() async {
    _dateFromController.text = _selectedFrom != null
        ? _selectedFrom!.toLocal().toIso8601String().split('T').first
        : '';
    _dateToController.text = _selectedTo != null
        ? _selectedTo!.toLocal().toIso8601String().split('T').first
        : '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hint: 'Date From',
                      controller: _dateFromController,
                      readOnly: true,
                      onTap: () async {
                        final d = await _pickDate(ctx, _selectedFrom);
                        if (d != null) {
                          setState(() {
                            _selectedFrom = d;
                            _dateFromController.text = d
                                .toLocal()
                                .toIso8601String()
                                .split('T')
                                .first;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomTextField(
                      hint: 'Date To',
                      controller: _dateToController,
                      readOnly: true,
                      onTap: () async {
                        final d = await _pickDate(
                          ctx,
                          _selectedTo ?? _selectedFrom,
                        );
                        if (d != null) {
                          setState(() {
                            _selectedTo = d;
                            _dateToController.text = d
                                .toLocal()
                                .toIso8601String()
                                .split('T')
                                .first;
                          });
                        }
                      },
                    ),
                  ),
                ].map((w) => Expanded(child: w)).toList(),
              ),

              const SizedBox(height: defaultSpacing),
              CustomTextField(
                hint: 'Photographer Name',
                controller: _photographerController,
              ),
              const SizedBox(height: defaultSpacing),
              CustomTextField(hint: 'Event Name', controller: _eventController),
              const SizedBox(height: largeSpacing),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFrom = null;
                        _selectedTo = null;
                        _dateFromController.clear();
                        _dateToController.clear();
                        _photographerController.clear();
                        _eventController.clear();
                        _moreFiltersApplied = false;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Clear'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _moreFiltersApplied =
                            _selectedFrom != null ||
                            _selectedTo != null ||
                            _photographerController.text.trim().isNotEmpty ||
                            _eventController.text.trim().isNotEmpty;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<SearchRepository>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Photos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              hint: 'Tags (separated by space)',
              controller: _tagsController,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _openMoreFilters,
                  child: Row(
                    children: [
                      const Text('More filters'),
                      if (_moreFiltersApplied) ...[
                        const SizedBox(width: defaultSpacing / 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultSpacing),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _performSearch(repo),
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: largeSpacing),

            if (!_loading && _photos.isEmpty)
              const Center(child: Text('Search photos using these filters...'))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: defaultSpacing,
                  mainAxisSpacing: defaultSpacing,
                ),
                itemBuilder: (context, i) {
                  final p = _photos[i];
                  return GestureDetector(
                    onTap: () => _openPhoto(p),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
                      child: CachedNetworkImage(
                        imageUrl: p.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (c, u, e) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
