import uuid

from django.db import models

from accounts.models import CustomUser
from photos.models import Photo


class Comment(models.Model):
    id = models.UUIDField(default=uuid.uuid4, primary_key=True, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False, related_name="comments")
    content = models.TextField(blank=False, null=False)
    parent_comment = models.ForeignKey(
        'self',
        on_delete=models.CASCADE, null=True,
        blank=True,
        related_name="child_comments",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class Like(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False, related_name="likes")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'photo'], name="unique_like")
        ]
