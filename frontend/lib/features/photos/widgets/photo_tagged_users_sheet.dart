import 'package:flutter/material.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/screen_utils.dart';
import 'package:frontend/features/auth/models/user.dart';
import 'package:frontend/core/widgets/user_avatar.dart';

Future<void> showTaggedUsersSheet({
  required BuildContext context,
  required List<User> users,
}) async {
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
      final safeBottom = ScreenUtils.safeBottom(sheetContext);
      final displayUsers = List<User>.from(users);

      return Padding(
        padding: EdgeInsets.fromLTRB(
          defaultSpacing,
          defaultSpacing,
          defaultSpacing,
          safeBottom + defaultSpacing,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photoDetailTaggedUsersTitle,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: defaultSpacing),
            if (displayUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: defaultSpacing),
                child: Text(
                  photoDetailNoTaggedUsers,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: displayUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = displayUsers[index];
                    final displayName = user.name.isNotEmpty
                        ? user.name
                        : user.username;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: UserAvatar(
                        username: user.name,
                        profilePicture: user.profilePicture,
                        size: 44,
                      ),
                      title: Text(displayName),
                      subtitle: Text('@${user.username}'),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
