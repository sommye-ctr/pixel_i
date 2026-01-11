import 'package:flutter/material.dart';
import '../../../core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/features/photos/models/photo.dart';

void showPhotoInfoSheet(BuildContext context, Photo photo) {
  final meta = photo.meta ?? <String, dynamic>{};
  final userTags =
      photo.userTags ??
      (meta['user_tags'] is List
          ? List<String>.from(meta['user_tags'] as List)
          : <String>[]);
  final autoTags =
      photo.autoTags ??
      (meta['auto_tags'] is List
          ? List<String>.from(meta['auto_tags'] as List)
          : <String>[]);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final tags = [
        Text(
          photoInfoTagsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: defaultSpacing),
        if (userTags.isEmpty && autoTags.isEmpty) const Text(photoInfoNoTags),
        if (userTags.isNotEmpty || autoTags.isNotEmpty)
          Wrap(
            spacing: defaultSpacing,
            runSpacing: defaultSpacing,
            children: [
              ...userTags,
              ...autoTags,
            ].map((t) => Chip(label: Text(t))).toList(),
          ),
        Divider(),
      ];

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tags,
              Text(
                photoInfoMetaTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: defaultSpacing),
              if (meta.isEmpty) const Text('No metadata available'),
              for (final entry in meta.entries)
                if (entry.key != 'user_tags' && entry.key != 'auto_tags')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: defaultSpacing),
                        Expanded(child: Text('${entry.value}')),
                      ],
                    ),
                  ),
              const SizedBox(height: largeSpacing),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}
