import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Model


class Role(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=30, unique=True, blank=False, null=False)

    def __str__(self):
        return self.title


class CustomUser(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    email = models.EmailField(unique=True)
    name = models.CharField(max_length=180, blank=False, null=False)
    profile_pic = models.URLField(blank=True, null=True)
    batch = models.CharField(max_length=32, blank=True, null=True)
    department = models.CharField(max_length=120, blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    role = models.ForeignKey(Role, on_delete=models.PROTECT, null=False)  # roles cannot be deleted

    def __str__(self):
        return self.username
