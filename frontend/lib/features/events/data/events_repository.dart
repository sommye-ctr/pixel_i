import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/events/models/event.dart';

class EventsRepository {
  final ApiClient apiClient;
  EventsRepository(this.apiClient);

  Future<List<Event>> fetchEvents() async {
    // Add backend fetching logic here

    final String response = await rootBundle.loadString(
      'assets/json/events.json',
    );
    final List<dynamic> data = json.decode(response);
    final List<Event> events = data.map((json) => Event.fromMap(json)).toList();
    return events;
  }

  Future<Event> createEvent({
    required String title,
    required String readPerm,
    required String writePerm,
  }) async {
    final res = await apiClient.post<Map<String, dynamic>>(
      '/events/',
      data: {'title': title, 'read_perm': readPerm, 'write_perm': writePerm},
    );
    final data = res.data ?? {};
    return Event.fromMap(data);
  }
}
