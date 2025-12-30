import uuid

from django.db import models

from accounts.models import CustomUser


class Notification(models.Model):
    class NotificationVerb(models.Choices):
        TAGGED = "TAGGED"
        LIKED = "LIKED"
        COMMENTED = "COMMENTED"
        EVENT_PHOTO_ADDED = "EVENT_PHOTO_ADDED"

    class NotificationTarget(models.Choices):
        PHOTO = "PHOTO"
        EVENT = "EVENT"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False,
                                  related_name="notifications_received")
    actor = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name="notifications_sent")
    verb = models.CharField(max_length=50, choices=NotificationVerb, blank=False, null=False)
    target_type = models.CharField(max_length=50, choices=NotificationTarget, blank=False, null=False)
    target_id = models.UUIDField(blank=False, null=False)
    data = models.JSONField(default=dict, blank=True)

    read = models.BooleanField(default=False)
    deleted = models.BooleanField(default=False)
    dedupe_key = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["recipient", "read"]),
            models.Index(fields=["recipient", "-created_at"]),
        ]
        ordering = ["-created_at"]
    def __str__(self):
        return f"Notification from {self.actor_id} to {self.recipient_id}"
