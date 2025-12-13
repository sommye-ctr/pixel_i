from django.db import transaction
from django.utils import timezone

from notifications.models import Notification


def create_notification(
        *,
        recipient,
        verb,
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
            existing.timestamp = timezone.now()
            existing.save(update_fields=['timestamp'])
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
    # send fcm message
    return notif
