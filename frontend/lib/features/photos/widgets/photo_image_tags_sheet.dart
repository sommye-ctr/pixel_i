import 'package:flutter/material.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';

Future<void> showImageTagsSheet({
  required BuildContext context,
  required List<String> initialTags,
  required void Function(List<String> tags) onSubmit,
}) async {
  final controller = TextEditingController();
  final tags = [...initialTags];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(largeRoundEdgeRadius),
      ),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: defaultSpacing,
          right: defaultSpacing,
          top: defaultSpacing,
          bottom: ScreenUtils.safeBottom(sheetContext) + defaultSpacing,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            void addTag() {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              if (!tags.contains(text)) {
                setSheetState(() => tags.add(text));
              }
              controller.clear();
            }

            void removeTag(String tag) {
              setSheetState(() => tags.remove(tag));
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photoUploadAddImageTags,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: defaultSpacing),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => addTag(),
                  decoration: InputDecoration(
                    hintText: photoUploadTagLabel,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addTag,
                    ),
                  ),
                ),
                const SizedBox(height: defaultSpacing),
                Wrap(
                  spacing: defaultSpacing / 2,
                  runSpacing: defaultSpacing / 2,
                  children: tags.isEmpty
                      ? [
                          Text(
                            photoUploadNoTagsYet,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ]
                      : tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () => removeTag(tag),
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: defaultSpacing * 1.5),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      onSubmit(List<String>.from(tags));
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text(photoUploadDone),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
