import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:frontend/features/events/bloc/events_bloc.dart';
import 'package:frontend/features/events/bloc/events_event.dart';
import 'package:frontend/features/events/bloc/events_state.dart';
import 'package:frontend/features/events/widgets/event_card.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsBloc>().add(EventsRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        Widget body;

        if (state is EventsLoadInProgress) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state is EventsLoadFailure) {
          body = Center(child: Text('Failed to load events: ${state.error}'));
        } else if (state is EventsLoadSuccess) {
          final events = state.events;
          if (events.isEmpty) {
            body = const Center(child: Text('No events available'));
          } else {
            body = Padding(
              padding: const EdgeInsets.all(defaultSpacing),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: defaultSpacing,
                crossAxisSpacing: defaultSpacing,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return EventCard(
                    event: events[index],
                    onTap: () {
                      final event = events[index];
                      context.push(
                        '/event/${event.id}?title=${Uri.encodeComponent(event.title)}',
                      );
                    },
                  );
                },
              ),
            );
          }
        } else {
          body = const SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              eventsTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  state.showOnlyMyEvents ? LucideIcons.x : LucideIcons.user,
                ),
                onPressed: () {
                  if (state.showOnlyMyEvents) {
                    context.read<EventsBloc>().add(EventsRequested());
                    ToastUtils.showShort('Showing all events');
                  } else {
                    context.read<EventsBloc>().add(const MyEventsRequested());
                    ToastUtils.showShort('Showing your events');
                  }
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: () async {
                  final result = await context.push<bool>('/event/create');
                  if (result == true) {
                    if (context.mounted) {
                      context.read<EventsBloc>().add(EventsRequested());
                    }
                  }
                },
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}
