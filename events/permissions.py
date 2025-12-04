from django.db import models
from rest_framework import permissions


def user_is_img(user):
    role = getattr(user, "role", None)
    if role:
        return getattr(role, "title", "") == "img"
    return False


def user_is_admin(user):
    role = getattr(user, "role", None)
    if role:
        return getattr(role, "title", "") == "admin"
    return False


class EventPermission(models.TextChoices):
    PUBLIC = "PUB", "Public"
    IMG = "IMG", "IMG Member"
    PRIVATE = "PRV", "Private"


class IsCoordinator(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.coordinator_id == request.user.id


class CreateEventPermission(permissions.IsAuthenticated):
    pass


class DeleteEventPermission(IsCoordinator):
    pass


class RetrieveEventPermission(permissions.BasePermission):

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        # if admin
        if user_is_admin(user):
            return True

        # if coordinator of the event
        if getattr(user, "id", None) == getattr(obj, "coordinator_id", None):
            return True

        is_img_member = user_is_img(user)
        read_perm = getattr(obj, "read_perm", None)
        # if img member so return all img or public ones
        if is_img_member:
            return read_perm in [EventPermission.PUBLIC, EventPermission.IMG]

        return read_perm == EventPermission.PUBLIC
