import uuid

from django.db import models
from django.utils import timezone

from accounts.models import CustomUser
from events.models import Event


class ReadPerm(models.TextChoices):
    PUBLIC = "PUB", "Public"
    IMG = "IMG", "IMG Member"
    PRIVATE = "PRV", "Private"


class SharePerm(models.TextChoices):
    OWNER_ROLES = "OR", "Owner or Roles"
    ANYONE = "AN", "Anyone"
    DISABLED = "DI", "Disabled"


class Photo(models.Model):
    class PhotoStatus(models.TextChoices):
        PENDING = "PE", "Pending"
        PROCESSING = "PR", "Processing"
        COMPLETED = "CO", "Completed"
        FAILED = "FA", "Failed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(default=timezone.now)
    auto_tags = models.JSONField(default=list)
    user_tags = models.JSONField(default=list)
    meta = models.JSONField(default=dict)
    status = models.CharField(choices=PhotoStatus, default=PhotoStatus.PENDING)
    processing_errors = models.JSONField(default=dict, blank=True)
    read_perm = models.CharField(choices=ReadPerm, default=ReadPerm.PUBLIC)
    share_perm = models.CharField(choices=SharePerm, default=SharePerm.OWNER_ROLES)
    downloads = models.BigIntegerField(default=0)
    views = models.BigIntegerField(default=0)

    photographer = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False, related_name="photos")
    event = models.ForeignKey(Event, on_delete=models.PROTECT, null=False, related_name="photos")

    width = models.IntegerField(null=True, blank=True)
    height = models.IntegerField(null=True, blank=True)

    original_path = models.TextField(default="")
    thumbnail_url = models.TextField(default="")
    watermarked_url = models.TextField(default="")
    tagged_users = models.ManyToManyField(
        CustomUser, through="PhotoTag", related_name="tagged_photos"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class PhotoTag(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'photo'], name="unique_tag")
        ]


class PhotoShare(models.Model):
    class PhotoVariant(models.TextChoices):
        WATERMARKED = "W"
        ORIGINAL = "O"

    token = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE, null=False)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=False)
    variant_key = models.CharField(choices=PhotoVariant, default=PhotoVariant.ORIGINAL)
    expires_at = models.DateTimeField(null=False, blank=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
