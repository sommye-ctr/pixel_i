import 'package:flutter/material.dart';
import 'package:frontend/core/utils/date_utils.dart';
import 'package:frontend/core/widgets/custom_text_field.dart';
import 'package:frontend/features/comments/models/comment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/comments_repository.dart';
import '../bloc/comments_bloc.dart';
import '../../../core/resources/style.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String photoId;

  const CommentsBottomSheet({super.key, required this.photoId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final TextEditingController _controller;
  String? _replyToCommentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildcommentItem(
    BuildContext context,
    Comment c,
    List<Comment>? replies,
    bool isLoadingReplies,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Text(
                  c.user.username.isNotEmpty
                      ? c.user.username[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: defaultSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.user.username,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: defaultSpacing),
                        Text(
                          timeAgo(c.createdAt),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultSpacing / 2),
                    Text(
                      c.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.reply, size: 18),
                onPressed: () {
                  setState(() {
                    _replyToCommentId = c.id;
                    _replyToUsername = c.user.username;
                  });
                },
              ),
            ],
          ),

          if (c.childCount != null && c.childCount! > 0 && replies == null)
            Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 8),
              child: isLoadingReplies
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () {
                        context.read<CommentsBloc>().add(
                          CommentRepliesLoadRequested(widget.photoId, c.id),
                        );
                      },
                      child: const Text('Load replies'),
                    ),
            ),
          if (replies != null)
            Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 8),
              child: Column(
                children: replies.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(
                            r.user.username.isNotEmpty
                                ? r.user.username[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          CommentsBloc(ctx.read<CommentsRepository>())
            ..add(CommentsLoadRequested(widget.photoId)),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(largeRoundEdgeRadius),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultSpacing,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<CommentsBloc, CommentsState>(
                    builder: (context, state) {
                      if (state.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = state.comments;
                      return NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200) {
                            context.read<CommentsBloc>().add(
                                  CommentsLoadMoreRequested(widget.photoId),
                                );
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultSpacing,
                            vertical: defaultSpacing,
                          ),
                          itemCount: comments.length + (state.hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= comments.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final c = comments[index];
                            final replies = state.replies[c.id];
                            final isLoadingReplies =
                                state.loadingReplies[c.id] ?? false;
                            return _buildcommentItem(
                              context,
                              c,
                              replies,
                              isLoadingReplies,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.only(
                    left: defaultSpacing,
                    right: defaultSpacing,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        defaultSpacing,
                    top: defaultSpacing,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _replyToCommentId != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_replyToCommentId != null &&
                                  _replyToUsername != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    top: 4,
                                    right: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Replying to @$_replyToUsername',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _replyToCommentId = null;
                                            _replyToUsername = null;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              CustomTextField(
                                hint:
                                    _replyToCommentId != null &&
                                        _replyToUsername != null
                                    ? 'Reply to @$_replyToUsername'
                                    : 'Add a comment...',
                                controller: _controller,
                                keyboardType: TextInputType.multiline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: defaultSpacing),
                      IconButton(
                        icon: const Icon(LucideIcons.send),
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isEmpty) return;
                          context.read<CommentsBloc>().add(
                            SendCommentRequested(
                              widget.photoId,
                              text,
                              parentId: _replyToCommentId,
                            ),
                          );
                          _controller.clear();
                          setState(() {
                            _replyToCommentId = null;
                            _replyToUsername = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
