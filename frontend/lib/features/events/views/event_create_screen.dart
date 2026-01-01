import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/resources/style.dart';
import 'package:frontend/core/utils/toast_utils.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/features/events/bloc/event_create_bloc.dart';
import 'package:frontend/features/events/bloc/event_create_event.dart';
import 'package:frontend/features/events/bloc/event_create_state.dart';
import 'package:go_router/go_router.dart';

enum EventPermission {
  pub('PUB', 'Public'),
  img('IMG', 'IMG Member'),
  prv('PRV', 'Private');

  final String value;
  final String label;

  const EventPermission(this.value, this.label);
}

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _titleController = TextEditingController();
  EventPermission _selectedReadPerm = EventPermission.pub;
  EventPermission _selectedWritePerm = EventPermission.pub;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ToastUtils.showShort('Please enter event title');
      return;
    }

    context.read<EventCreateBloc>().add(
      EventCreateRequested(
        title: title,
        readPerm: _selectedReadPerm.value,
        writePerm: _selectedWritePerm.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventCreateBloc, EventCreateState>(
      listener: (context, state) {
        if (state is EventCreateSuccess) {
          ToastUtils.showShort('Event created successfully');
          context.pop(true);
        } else if (state is EventCreateFailure) {
          ToastUtils.showLong('Failed to create event: ${state.error}');
        }
      },
      child: BlocBuilder<EventCreateBloc, EventCreateState>(
        builder: (context, state) {
          final isLoading = state is EventCreateInProgress;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create Event'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  CustomTextField(
                    controller: _titleController,
                    hint: 'Enter event title',
                  ),
                  const SizedBox(height: largeSpacing),

                  // Read Permission
                  Text(
                    'Read Permission',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: defaultSpacing),
                  Wrap(
                    spacing: defaultSpacing,
                    children: EventPermission.values.map((perm) {
                      return ChoiceChip(
                        label: Text(perm.label),
                        selected: _selectedReadPerm == perm,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedReadPerm = perm;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: largeSpacing),

                  // Write Permission
                  Text(
                    'Write Permission',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: defaultSpacing),
                  Wrap(
                    spacing: defaultSpacing,
                    children: EventPermission.values.map((perm) {
                      return ChoiceChip(
                        label: Text(perm.label),
                        selected: _selectedWritePerm == perm,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedWritePerm = perm;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: largeSpacing),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createEvent,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Event'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
