import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/features/events/models/event.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  Widget _buildImage() {
    final cover = event.coverPhoto;
    final imageUrl = cover?.thumbnailUrl ?? '';
    final double? aspectRatio = (cover?.width != null && cover?.height != null)
        ? (cover!.width! > 0 && cover.height! > 0)
              ? cover.width! / cover.height!
              : null
        : null;

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        height: 200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );

    final stack = Stack(
      children: [
        image,
        Positioned(
          top: defaultSpacing,
          right: defaultSpacing,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: defaultSpacing,
              vertical: defaultSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: event.readPerm == EventPermission.pub
                  ? Colors.green.withOpacity(0.9)
                  : Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  event.readPerm == EventPermission.pub
                      ? LucideIcons.globe
                      : LucideIcons.lock,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  event.readPerm.label,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio, child: stack);
    }

    return SizedBox(width: double.infinity, child: stack);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(),
            // Event Details
            Padding(
              padding: const EdgeInsets.all(defaultSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Event Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: defaultSpacing),
                  // Images Count and Coordinator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.images,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: defaultSpacing / 2),
                          Text(
                            '${event.imagesCount} files',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            event.coordinator.profilePicture != null
                            ? CachedNetworkImageProvider(
                                event.coordinator.profilePicture!,
                              )
                            : null,
                        child: event.coordinator.profilePicture == null
                            ? Text(event.coordinator.name[0].toUpperCase())
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
