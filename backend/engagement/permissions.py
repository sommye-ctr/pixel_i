from rest_framework import permissions
from rest_framework.generics import get_object_or_404

from photos.models import Photo
from photos.permissions import can_read_photo


class EngagementPermission(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method != "POST":
            return True
        user = request.user

        if not user or not user.is_authenticated:
            return False

        photo_id = view.kwargs.get("photo_id")
        photo = get_object_or_404(Photo, pk=photo_id)
        return can_read_photo(user, photo)


class IsOwner(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        return user and user.is_authenticated and getattr(user, 'id', None) == obj.user_id
