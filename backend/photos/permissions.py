from rest_framework import permissions
from rest_framework.generics import get_object_or_404

from accounts.models import CustomUser
from events.permissions import EventPermission
from photos.models import Photo, ReadPerm, SharePerm
from utils.user_utils import user_is_admin, user_is_img


class IsPhotographer(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return getattr(obj, "photographer_id", None) == getattr(request.user, "id", None)


class IsEventCoordinator(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        event = getattr(obj, 'event', None)
        if not event:
            return False

        return event and is_event_coordinator(request.user, event)


def is_event_coordinator(user, event):
    return event.coordinator_id == getattr(user, 'id', None)


def is_admin_or_photographer(user, obj):
    return user_is_admin(user) \
        or getattr(obj, "photographer_id", None) == getattr(user, "id", None)


def can_read_photo(user, obj):
    if is_admin_or_photographer(user, obj) or is_event_coordinator(user, obj.event):
        return True

    perm = getattr(obj, "read_perm", None)
    if perm == ReadPerm.PUBLIC:
        return True
    elif perm == ReadPerm.IMG:
        return user_is_img(user)

    return False


def can_share_photo(user: CustomUser, photo: Photo):
    perm = getattr(photo, "share_perm", None)
    if perm == SharePerm.DISABLED:
        return False
    if perm == SharePerm.ANYONE:
        return True
    return is_admin_or_photographer(user, photo) or photo.event.coordinator.id == user.id


class PhotoUploadPermission(permissions.BasePermission):
    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        event = view.get_event()
        if not event:
            return False

        if user_is_admin(user) or event.coordinator_id == user.id:
            return True

        perm = event.write_perm
        if perm == EventPermission.PUBLIC:
            return True
        elif perm == EventPermission.IMG:
            return user_is_img(user)

        return False


class PhotoReadPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        return can_read_photo(user, obj)


class PhotoShareRevokePermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        if getattr(user, 'id', None) == obj.created_by.id:
            return True

        return False


class PhotoShareCreatePermission(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method != "POST":
            return True

        if not request.user or not request.user.is_authenticated:
            return False

        photo_id = view.kwargs.get("photo_id")
        if photo_id is None:
            return False

        photo = get_object_or_404(Photo, pk=photo_id)

        return can_share_photo(request.user, photo)
