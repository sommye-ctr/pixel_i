import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final String? profilePicture;
  final double size;

  const UserAvatar({
    super.key,
    required this.username,
    this.profilePicture,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUsername = username.trim();
    final hasProfilePic = (profilePicture ?? '').trim().isNotEmpty;
    final initial = trimmedUsername.isNotEmpty
        ? trimmedUsername[0].toUpperCase()
        : '?';

    Widget buildFallback() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
        child: Text(
          initial,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    if (!hasProfilePic) {
      return buildFallback();
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: profilePicture!.trim(),
          fit: BoxFit.cover,
          placeholder: (_, _) => buildFallback(),
          errorWidget: (_, _, _) => buildFallback(),
        ),
      ),
    );
  }
}
