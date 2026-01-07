import 'package:frontend/features/notifications/models/notification_item.dart';

class NotificationUtils {
  static String? formatNotification(NotificationItem item) {
    if (item.verb.endsWith("EVENT_PHOTO_ADDED")) {
      final count =
          item.data.containsKey("count") &&
              item.data["count"] is int &&
              item.data["count"] > 1
          ? "${item.data["count"]} photos"
          : "a photo";
      return "${item.actorUsername} added $count to an event";
    }

    String? title = item.actorUsername;
    if (item.data.containsKey('count') &&
        item.data['count'] is int &&
        item.data['count'] > 1) {
      title = "${item.data['count']} users";
    }

    String? action;
    if (item.verb.endsWith('LIKED')) action = 'liked your';
    if (item.verb.endsWith('COMMENTED')) action = 'commented on your';
    if (item.verb.endsWith('TAGGED')) action = 'tagged you in';

    String? targetText;
    if (item.targetType.endsWith('PHOTO')) targetText = 'photo';
    if (item.targetType.endsWith('EVENT')) targetText = 'event';

    if (action != null && targetText != null) {
      return '$title $action $targetText';
    }
    return null;
  }
}
