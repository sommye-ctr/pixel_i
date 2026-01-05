import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:frontend/features/photos/data/photos_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

enum PhotoVariant { watermarked, original }

Future<void> showPhotoShareSheet({
  required BuildContext context,
  required String photoId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(largeRoundEdgeRadius),
      ),
    ),
    builder: (sheetContext) {
      return PhotoShareBottomSheet(photoId: photoId);
    },
  );
}

class PhotoShareBottomSheet extends StatefulWidget {
  final String photoId;

  const PhotoShareBottomSheet({super.key, required this.photoId});

  @override
  State<PhotoShareBottomSheet> createState() => _PhotoShareBottomSheetState();
}

class _PhotoShareBottomSheetState extends State<PhotoShareBottomSheet> {
  PhotoVariant _selectedVariant = PhotoVariant.watermarked;
  DateTime? _selectedExpiry;
  bool _isLoading = false;
  String? _shareUrl;

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 15));

    final date = await showDatePicker(
      context: context,
      initialDate: minTime,
      firstDate: minTime,
      lastDate: minTime.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minTime),
    );

    if (time == null) return;
    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Validate that selected time is at least 15 minutes in the future
    if (selectedDateTime.isBefore(minTime)) {
      if (!mounted) return;
      ToastUtils.showLong('Expiry time must be at least 15 minutes from now');
      return;
    }

    setState(() {
      _selectedExpiry = selectedDateTime;
    });
  }

  void _handleProceed() async {
    if (_selectedExpiry == null) {
      ToastUtils.showShort("Select an expiry to proceed.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final variantKey = _selectedVariant == PhotoVariant.watermarked
          ? 'W'
          : 'O';
      final repo = context.read<PhotosRepository>();

      final response = await repo.sharePhoto(
        photoId: widget.photoId,
        variantKey: variantKey,
        expiresAt: _selectedExpiry!,
      );

      if (mounted) {
        setState(() {
          _shareUrl = response.shareUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtils.showLong('Error sharing photo: $e');
        Navigator.of(context).pop();
      }
    }
  }

  void _copyToClipboard() {
    if (_shareUrl != null) {
      Clipboard.setData(ClipboardData(text: _shareUrl!));
      ToastUtils.showShort('Link copied to clipboard');
    }
  }

  void _shareLink() {
    if (_shareUrl != null) {
      Share.share(_shareUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = ScreenUtils.safeBottom(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        defaultSpacing,
        defaultSpacing,
        defaultSpacing,
        safeBottom + defaultSpacing,
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _shareUrl != null
          ? _buildShareUrlState()
          : _buildFormState(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: largeSpacing * 2),
        const CircularProgressIndicator(),
        const SizedBox(height: largeSpacing),
        Text(
          'Generating share link...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: largeSpacing * 2),
      ],
    );
  }

  Widget _buildShareUrlState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Share Link Ready',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: largeSpacing),
        Container(
          padding: const EdgeInsets.all(defaultSpacing),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _shareUrl!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: defaultSpacing),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 20),
                onPressed: _copyToClipboard,
                tooltip: 'Copy',
              ),
            ],
          ),
        ),
        const SizedBox(height: largeSpacing),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(LucideIcons.copy),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: defaultSpacing),
                  child: Text('Copy Link'),
                ),
              ),
            ),
            const SizedBox(width: defaultSpacing),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareLink,
                icon: const Icon(LucideIcons.share2),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: defaultSpacing),
                  child: Text('Share'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Photo',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: largeSpacing),
        Text('Photo Variant', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: defaultSpacing),
        Row(
          children: [
            _buildVariantChip(
              label: 'Watermarked',
              variant: PhotoVariant.watermarked,
              isSelected: _selectedVariant == PhotoVariant.watermarked,
            ),
            const SizedBox(width: defaultSpacing),
            _buildVariantChip(
              label: 'Original',
              variant: PhotoVariant.original,
              isSelected: _selectedVariant == PhotoVariant.original,
            ),
          ],
        ),
        const SizedBox(height: largeSpacing),
        Text('Expiry Time', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: defaultSpacing),
        GestureDetector(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: defaultSpacing,
              vertical: defaultSpacing,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select expiry date & time',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_selectedExpiry != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _formatDateTime(_selectedExpiry!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                Icon(
                  LucideIcons.calendar,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_selectedExpiry != null)
          Padding(
            padding: const EdgeInsets.only(top: defaultSpacing),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedExpiry = null;
                });
              },
              child: Text(
                'Clear',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        const SizedBox(height: largeSpacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleProceed,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultSpacing),
              child: Text('Proceed'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantChip({
    required String label,
    required PhotoVariant variant,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedVariant = variant;
          });
        }
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    String dateStr;
    if (dateTime.year == today.year &&
        dateTime.month == today.month &&
        dateTime.day == today.day) {
      dateStr = 'Today';
    } else if (dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dateStr at $timeStr';
  }
}
