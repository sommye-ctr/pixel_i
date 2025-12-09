from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, parsers, generics
from rest_framework.generics import get_object_or_404
from rest_framework.permissions import IsAuthenticated

from engagement.serializers import LikeSerializer
from photos.models import Photo, PhotoShare
from photos.permissions import PhotoReadPermission, ReadPerm, IsPhotographer, IsEventCoordinator, \
    PhotoShareCreatePermission, PhotoShareRevokePermission
from photos.serializers import PhotoSerializer, PhotoListSerializer, PhotoWriteSerializer, PhotoShareSerializer
from photos.tasks import generate_image_variants_task
from utils.user_utils import user_is_admin, user_is_img


class PhotoView(viewsets.ModelViewSet):
    queryset = Photo.objects.all()
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def perform_create(self, serializer):
        photo = serializer.save(status=Photo.PhotoStatus.PROCESSING)
        generate_image_variants_task.delay(photo.id)

    def get_serializer_class(self):
        if self.action == 'list':
            return PhotoListSerializer
        elif self.action == 'retrieve':
            return PhotoSerializer
        return PhotoWriteSerializer

    def get_permissions(self):
        if user_is_admin(self.request.user):
            return [IsAuthenticated()]

        if self.action == 'create':
            return [IsAuthenticated()]
        elif self.action == 'retrieve':
            return [PhotoReadPermission()]
        elif self.action == 'list':
            return [IsAuthenticated()]
        elif self.action in ("update", "partial_update"):
            return [IsPhotographer()]
        elif self.action == 'destroy':
            return [IsPhotographer(), IsEventCoordinator()]
        return [IsAuthenticated()]

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


class PhotoLikesView(generics.ListAPIView):
    serializer_class = LikeSerializer
    permission_classes = [PhotoReadPermission]

    def get_queryset(self):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        return photo.likes.all()


class PhotoShareCreateView(generics.CreateAPIView):
    serializer_class = PhotoShareSerializer
    permission_classes = [PhotoShareCreatePermission]

    def perform_create(self, serializer):
        photo_id = self.kwargs["photo_id"]
        photo = get_object_or_404(Photo, pk=photo_id)

        serializer.save(
            photo=photo,
            created_by=self.request.user,
        )


class PhotoShareDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = PhotoShareSerializer
    lookup_field = "token"
    lookup_url_kwarg = "token"

    def get_queryset(self):
        now = timezone.now()
        return PhotoShare.objects.filter(
            expires_at__gt=now
        )

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        elif self.request.method == "DELETE":
            return [PhotoShareRevokePermission()]
        return [IsAuthenticated()]
