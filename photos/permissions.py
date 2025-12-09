from rest_framework import permissions
from rest_framework.generics import get_object_or_404

from photos.models import Photo, ReadPerm
from utils.user_utils import user_is_admin, user_is_img


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


def can_read_photo(user, obj):
    if can_see_all_columns(user, obj):
        return True

    perm = getattr(obj, "read_perm", None)
    if perm == ReadPerm.PUBLIC:
        return True
    elif perm == ReadPerm.IMG:
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
        return can_read_photo(request.user, photo)
