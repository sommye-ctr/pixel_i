from django.db.models import Q
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from photos.models import Photo
from photos.permissions import PhotoReadPermission, ReadPerm, IsPhotographer, IsEventCoordinator
from photos.serializers import PhotoSerializer, PhotoListSerializer, PhotoWriteSerializer
from utils.user_utils import user_is_admin, user_is_img


class PhotoDetailView(viewsets.ModelViewSet):
    queryset = Photo.objects.all()

    def get_serializer_class(self):
        if self.action == 'list':
            return PhotoListSerializer
        elif self.action == 'retrieve':
            return PhotoSerializer
        return PhotoWriteSerializer

    def get_permissions(self):
        if user_is_admin(self.request.user):
            return [IsAuthenticated]

        if self.action == 'create':
            return [IsAuthenticated]
        elif self.action == 'retrieve':
            return [PhotoReadPermission]
        elif self.action == 'list':
            return [IsAuthenticated]
        elif self.action in ("update", "partial_update"):
            return [IsPhotographer]
        elif self.action == 'destroy':
            return [IsPhotographer, IsEventCoordinator]
        return [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        if self.action != "list" or user_is_admin(user):
            return qs
        if not user.is_authenticated:
            return qs.none()

        q_photographer = Q(photographer=user)
        q_img = Q(read_perm=ReadPerm.IMG)
        q_public = Q(read_perm=ReadPerm.PUBLIC)

        if user_is_img(user):
            return qs.filter(q_photographer | q_img | q_public).distinct()
        return qs.filter(q_photographer | q_public).distinct()
