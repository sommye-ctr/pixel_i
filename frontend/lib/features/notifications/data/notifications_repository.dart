import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../models/notification_item.dart';

class NotificationsRepository {
  final ApiClient api;
  final TokenStorage tokenStorage;

  NotificationsRepository(this.api, this.tokenStorage);

  Future<List<NotificationItem>> fetchNotifications() async {
    final res = await api.get<List<dynamic>>('/notifications/');
    final data = res.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((m) => NotificationItem.fromMap(m))
        .toList();
  }

  Future<NotificationItem?> markAsRead(String id) async {
    final res = await api.patch<Map<String, dynamic>>(
      '/notifications/$id/',
      data: {'read': true},
    );
    final data = res.data;
    if (data != null) {
      return NotificationItem.fromMap(data);
    }
    return null;
  }

  Uri _buildWebSocketUri(String path, {Map<String, String>? query}) {
    final override = notificationsWsBaseUrl.trim();
    final base = override.isNotEmpty
        ? Uri.parse(override)
        : Uri.parse(backendBaseUrl);

    final scheme = () {
      if (base.scheme == 'wss' || base.scheme == 'ws') return base.scheme;
      return base.scheme == 'https' ? 'wss' : 'ws';
    }();

    return Uri(
      scheme: scheme,
      host: base.host.isNotEmpty ? base.host : 'localhost',
      port: base.hasPort ? base.port : null,
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query,
    );
  }

  Future<WebSocketChannel> connectNotificationsChannel() async {
    final token = await tokenStorage.getAccessToken();
    final uri = _buildWebSocketUri(
      '/ws/notifications/',
      query: token != null ? {'token': token} : null,
    );
    final channel = IOWebSocketChannel.connect(uri);
    return channel;
  }
}
