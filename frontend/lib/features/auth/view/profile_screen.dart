import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/utils/index.dart';
import 'package:frontend/features/photos/data/photos_repository.dart';
import 'package:frontend/features/photos/view/tagged_in_photos_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';
import '../../../core/resources/style.dart';
import '../../../core/widgets/user_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state.user == null) {
        authBloc.add(AuthEvent.fetchCurrentUserProfile());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    final completer = Completer<void>();
    _subscription?.cancel();
    _subscription = context.read<AuthBloc>().stream.listen((state) {
      if (state.status != AuthStatus.loading) {
        if (!completer.isCompleted) completer.complete();
      }
    });
    context.read<AuthBloc>().add(AuthEvent.fetchCurrentUserProfile());
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  void _logout() {
    context.read<AuthBloc>().add(AuthEvent.logout());
    context.go('/');
  }

  void _showTaggedInPhotos(BuildContext context) {
    final photosRepository = context.read<PhotosRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TaggedInPhotosScreen(photosRepository: photosRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.error && state.error != null) {
          ToastUtils.showLong('$profileLoadingFailed: ${state.error}');
        }
        if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        final user = state.user;
        final isLoading = state.status == AuthStatus.loading;

        if (isLoading && user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == AuthStatus.error && user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(profileTitle)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(profileLoadingFailed),
                  const SizedBox(height: defaultSpacing),
                  OutlinedButton.icon(
                    onPressed: _refreshProfile,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text(profileRetry),
                  ),
                ],
              ),
            ),
          );
        }

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = _buildStats(user);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              profileTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: Icon(LucideIcons.pen)),
              IconButton(
                onPressed: isLoading ? null : _logout,
                icon: Icon(LucideIcons.logOut),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              padding: const EdgeInsets.all(largeSpacing),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: largeSpacing),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      username: user.name,
                      profilePicture: user.profilePicture,
                      size: 72,
                    ),
                    const SizedBox(width: largeSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: defaultSpacing / 2),
                          Text(
                            '@${user.username}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: largeSpacing * 1.5),
                SizedBox(
                  height: context.heightPercent(18),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stats.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: defaultSpacing),
                    itemBuilder: (context, index) {
                      return _StatCard(stat: stats[index]);
                    },
                  ),
                ),
                const SizedBox(height: largeSpacing * 1.5),
                ListTile(
                  title: Text(photosTaggedIn),
                  trailing: Icon(LucideIcons.chevronRight),
                  leading: Icon(LucideIcons.tag),
                  onTap: () => _showTaggedInPhotos(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ProfileStat> _buildStats(User user) {
    return [
      _ProfileStat(
        label: profileTotalPhotos,
        value: user.photosCount ?? 0,
        icon: LucideIcons.images,
      ),
      _ProfileStat(
        label: profileTotalEvents,
        value: user.eventsCount ?? 0,
        icon: LucideIcons.calendarClock,
      ),
      _ProfileStat(
        label: profileLikes,
        value: user.likesCount ?? 0,
        icon: LucideIcons.heart,
      ),
      _ProfileStat(
        label: profileDownloads,
        value: user.downloadsCount ?? 0,
        icon: LucideIcons.download,
      ),
    ];
  }
}

class _ProfileStat {
  final String label;
  final int value;
  final IconData icon;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _ProfileStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: context.widthPercent(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
        color: colorScheme.surfaceVariant,
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Icon(stat.icon, color: colorScheme.primary),
          ),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            stat.value.toString(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
