import 'package:flutter/material.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/models/user_suggestion.dart';

Future<void> showTagUsersSheet({
  required BuildContext context,
  required AuthRepository authRepository,
  required List<String> initialUsernames,
  required void Function(List<String> usernames) onSubmit,
}) async {
  final searchController = TextEditingController();
  final selected = {...initialUsernames};

  List<UserSuggestion> results = [];
  bool loading = false;
  String? error;

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
          bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom + defaultSpacing,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> search() async {
              final query = searchController.text.trim();
              if (query.isEmpty) return;
              setSheetState(() {
                loading = true;
                error = null;
                results = const [];
              });
              try {
                final res = await authRepository.searchUsers(query: query);
                setSheetState(() => results = res);
              } catch (_) {
                setSheetState(() {
                  error = photoUploadUnableToSearch;
                  results = const [];
                });
              } finally {
                setSheetState(() => loading = false);
              }
            }

            void toggleUser(String username) {
              setSheetState(() {
                if (selected.contains(username)) {
                  selected.remove(username);
                } else {
                  selected.add(username);
                }
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photoUploadTagUsers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: defaultSpacing),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: photoUploadSearchUsers,
                        ),
                        onSubmitted: (_) => search(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: defaultSpacing),
                if (loading) const LinearProgressIndicator(),
                if (error != null) ...[
                  const SizedBox(height: defaultSpacing / 2),
                  Text(
                    error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: defaultSpacing / 2),
                if (results.isNotEmpty)
                  Wrap(
                    spacing: defaultSpacing / 2,
                    runSpacing: defaultSpacing / 2,
                    children: [
                      for (final user in results)
                        ChoiceChip(
                          label: Text(
                            '${user.name.isNotEmpty ? user.name : user.username} (@${user.username})',
                          ),
                          selected: selected.contains(user.username),
                          onSelected: (_) => toggleUser(user.username),
                        ),
                    ],
                  )
                else if (!loading && searchController.text.isNotEmpty)
                  Text(
                    photoUploadNoUsersFound,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: defaultSpacing * 1.5),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      onSubmit(List<String>.from(selected));
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
