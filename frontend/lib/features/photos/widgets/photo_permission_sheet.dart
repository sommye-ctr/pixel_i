import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/features/photos/models/photo.dart';

Future<void> showPermissionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T selected,
  required void Function(T value) onSelected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(largeRoundEdgeRadius),
      ),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(defaultSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultSpacing),
            Wrap(
              spacing: defaultSpacing / 2,
              runSpacing: defaultSpacing / 2,
              children: [
                for (final option in values)
                  ChoiceChip(
                    label: Text(
                      option is PhotoReadPermission
                          ? option.label
                          : option is PhotoSharePermission
                              ? option.label
                              : option.toString(),
                    ),
                    selected: option == selected,
                    onSelected: (_) {
                      onSelected(option);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
