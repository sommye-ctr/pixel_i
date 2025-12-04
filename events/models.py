import uuid

from django.db import models

from accounts.models import CustomUser
from events.permissions import EventPermission


class Event(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=120, null=False, blank=False)
    coordinator = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True)
    read_perm = models.CharField(choices=EventPermission, max_length=3, default=EventPermission.PUBLIC)
    write_perm = models.CharField(choices=EventPermission, max_length=3, default=EventPermission.PUBLIC)
