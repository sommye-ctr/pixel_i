from django.db import models
from rest_framework import permissions

from utils.user_utils import user_is_admin, user_is_img


class ReadPerm(models.TextChoices):
    PUBLIC = "PUB", "Public"
    IMG = "IMG", "IMG Member"
    PRIVATE = "PRV", "Private"


class SharePerm(models.TextChoices):
    OWNER_ROLES = "OR", "Owner or Roles"
    ANYONE = "AN", "Anyone"
    DISABLED = "DI", "Disabled"


class IsPhotographer(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return getattr(obj, "photographer_id", None) == getattr(request.user, "id", None)


class IsEventCoordinator(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        event = getattr(obj, 'event', None)
        if not event:
            return False

        if event and getattr(event, 'coordinator_id', None) \
                == getattr(request.user, 'id', None):
            return True
        return False


def can_see_all_columns(user, obj):
    return user_is_admin(user) \
        or getattr(obj, "photographer_id", None) == getattr(user, "id", None)


class PhotoReadPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        if can_see_all_columns(user, obj):
            return True

        perm = getattr(obj, "read_perm", None)
        if perm == ReadPerm.PUBLIC:
            return True
        elif perm == ReadPerm.IMG:
            return user_is_img(user)

        return False
