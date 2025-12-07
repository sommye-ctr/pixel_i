import uuid

from django.db import models
from django.utils import timezone

from accounts.models import CustomUser
from events.models import Event
from photos.permissions import ReadPerm, SharePerm


class Photo(models.Model):
    class PhotoStatus(models.TextChoices):
        PENDING = "PE", "Pending"
        PROCESSING = "PR", "Processing"
        COMPLETED = "CO", "Completed"
        FAILED = "FA", "Failed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(default=timezone.now)
    # tags = models. TODO setup postgres to use array field
    meta = models.JSONField(default=dict)
    status = models.CharField(choices=PhotoStatus, default=PhotoStatus.PENDING)
    read_perm = models.CharField(choices=ReadPerm, default=ReadPerm.PUBLIC)
    share_perm = models.CharField(choices=SharePerm, default=SharePerm.OWNER_ROLES)
    downloads = models.BigIntegerField(default=0)
    views = models.BigIntegerField(default=0)

    photographer = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    event = models.ForeignKey(Event, on_delete=models.PROTECT, null=False)

    original_path = models.TextField(default="")
    thumbnail_path = models.TextField(default="")
    watermarked_path = models.TextField(default="")
    tagged_users = models.ManyToManyField(
        CustomUser, through="PhotoTags", related_name="tagged_photos"
    )


class PhotoTags(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user_id', 'photo_id'], name="unique_tag")
        ]


class PhotoShares(models.Model):
    class PhotoVariant(models.TextChoices):
        WATERMARKED = "W"
        ORIGINAL = "O"

    token = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    variant_key = models.CharField(choices=PhotoVariant, default=PhotoVariant.ORIGINAL)
    allows_download = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(default=timezone.now)
