import 'package:flutter/material.dart';
import 'package:frontend/core/resources/strings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          eventsTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.plus), onPressed: () {}),
        ],
      ),
      body: const Center(child: Text('Welcome to the Events Screen!')),
    );
  }
}
