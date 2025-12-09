import uuid

from django.db import models
from django.utils import timezone

from accounts.models import CustomUser
from photos.models import Photo


class Comment(models.Model):
    id = models.UUIDField(default=uuid.uuid4, primary_key=True, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)
    timestamp = models.DateTimeField(default=timezone.now)
    content = models.TextField(blank=False, null=False)
    parent_comment = models.ForeignKey(
        'self',
        on_delete=models.CASCADE, null=True,
        blank=True,
        related_name="child_comments",
    )


class Like(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)
    timestamp = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'photo'], name="unique_like")
        ]
