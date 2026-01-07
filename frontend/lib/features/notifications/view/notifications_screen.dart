import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/notification_utils.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/features/notifications/bloc/notifications_bloc.dart';
import '../models/notification_item.dart';
import 'package:frontend/core/utils/date_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          context.read<NotificationsBloc>().add(NotificationsLoadRequested()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listenWhen: (previous, current) => previous.error != current.error,
        listener: (context, state) {
          ToastUtils.showLong(state.error ?? '');
        },
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final n = state.items[index];
                return _NotificationTile(
                  item: n,
                  onMarkRead: () => context.read<NotificationsBloc>().add(
                    NotificationsMarkRead(n.id),
                  ),
                  onTap: () {
                    n.targetType.endsWith("EVENT")
                        ? context.push('/event/${n.targetId}')
                        : n.targetType.endsWith("PHOTO")
                        ? context.push('/photo/${n.targetId}')
                        : null;
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;
  final VoidCallback? onTap;
  const _NotificationTile({
    required this.item,
    required this.onMarkRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.read;
    final tileColor = isUnread
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : null;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isUnread
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(smallRoundEdgeRadius),
        ),
        child: ListTile(
          tileColor: tileColor,
          title: Text(NotificationUtils.formatNotification(item) ?? ''),
          subtitle: item.createdAt != null
              ? Text(
                  timeAgo(item.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          trailing: isUnread
              ? ClipOval(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: IconButton(
                      onPressed: onMarkRead,
                      icon: const Icon(LucideIcons.check),
                    ),
                  ),
                )
              : const Icon(LucideIcons.checkCheck),
          onTap: () {
            onMarkRead();
            onTap?.call();
          },
        ),
      ),
    );
  }
}
