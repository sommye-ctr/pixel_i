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
        target_type,
        target_id,
        actor=None,
        data=None,
        dedupe_key=None,
):
    if data is None:
        data = {}

    if dedupe_key:
        existing = Notification.objects.filter(
            recipient=recipient,
            dedupe_key=dedupe_key
        ).first()

        if existing:
            existing.created_at = timezone.now()
            existing.save(update_fields=['created_at', 'updated_at'])
            return existing

    with transaction.atomic():
        notif = Notification.objects.create(
            recipient=recipient,
            actor=actor,
            verb=verb,
            target_type=target_type,
            target_id=str(target_id),
            data=data,
            dedupe_key=dedupe_key,
        )

    # send websocket message
    channel_layer = get_channel_layer()

    actor_json = {} if not actor else {
        "id": str(actor.id),
        "username": actor.username,
    }
    async_to_sync(channel_layer.group_send)(
        f"user_{user_group(recipient.id)}",
        {
            "type": "send_notification",
            "data": {
                "id": str(notif.id),
                "verb": str(verb),
                "actor": actor_json,
                "target": {
                    "type": str(target_type),
                    "id": str(target_id),
                },
                "data": {},
                "timestamp": str(notif.created_at),
                "read": notif.read
            }
        }
    )

    # send fcm message
    return notif
