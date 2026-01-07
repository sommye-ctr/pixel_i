from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction
from django.utils import timezone

from notifications.consumers import user_group
from notifications.models import Notification


def create_notification(
        *,
        recipient,
        verb: Notification.NotificationVerb,
        target_type: Notification.NotificationTarget,
        target_id,
        actor=None,
        data=None,
        dedupe_key=None,
):
    data = data or {}

    with transaction.atomic():
        notif = None

        if dedupe_key:
            notif = (
                Notification.objects
                .select_for_update()
                .filter(recipient=recipient, dedupe_key=dedupe_key)
                .first()
            )

        if notif:
            merged_data = notif.data or {}
            for k, v in data.items():
                if isinstance(v, int):
                    merged_data[k] = merged_data.get(k, 0) + v
                else:
                    merged_data[k] = v

            notif.data = merged_data
            notif.updated_at = timezone.now()
            notif.save(update_fields=["data", "updated_at"])
        else:
            notif = Notification.objects.create(
                recipient=recipient,
                actor=actor,
                verb=verb,
                target_type=target_type,
                target_id=str(target_id),
                data=data,
                dedupe_key=dedupe_key,
            )

    # websocket
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        f"user_{user_group(recipient.id)}",
        {
            "type": "send_notification",
            "data": {
                "id": str(notif.id),
                "verb": verb.value,
                "actor": None if not actor else {
                    "id": str(actor.id),
                    "username": actor.username,
                },
                "target_id": str(target_id),
                "target_type": target_type.value,
                "data": notif.data,
                "timestamp": notif.updated_at.isoformat(),
                "read": notif.read,
            }
        }
    )

    return notif
