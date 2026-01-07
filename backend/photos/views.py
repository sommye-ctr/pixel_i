from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, parsers, generics, permissions, status
from rest_framework.generics import get_object_or_404
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from events.models import Event
from events.permissions import EventPermission
from notifications.models import Notification
from notifications.services import create_notification
from photos.models import Photo, PhotoShare
from photos.permissions import PhotoReadPermission, ReadPerm, IsPhotographer, IsEventCoordinator, \
    PhotoShareCreatePermission, PhotoShareRevokePermission, PhotoUploadPermission
from photos.serializers import PhotoReadSerializer, PhotoListSerializer, PhotoWriteSerializer, PhotoShareSerializer, \
    PhotoBulkUploadSerializer, PhotoSearchSerializer
from photos.services import PhotoSearchService
from photos.tasks import process_photo_task
from utils.user_utils import user_is_admin, user_is_img


class PhotoView(viewsets.ModelViewSet):
    queryset = Photo.objects.all()
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def perform_create(self, serializer):
        photo = serializer.save(status=Photo.PhotoStatus.PROCESSING)
        create_notification(
            recipient=photo.event.coordinator,
            verb=Notification.NotificationVerb.EVENT_PHOTO_ADDED,
            target_type=Notification.NotificationTarget.EVENT,
            target_id=photo.event.id,
            actor=self.request.user,
            dedupe_key=f"event_add:{photo.event.id}:actor:{self.request.user.id}",
            data={"count": 1}
        )
        process_photo_task.delay(photo.id)

    def get_serializer_class(self):
        if self.action == 'list':
            return PhotoListSerializer
        elif self.action == 'retrieve':
            return PhotoReadSerializer
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


class EventPhotosView(generics.ListAPIView):
    serializer_class = PhotoListSerializer
    permissions_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        event = get_object_or_404(Event, id=self.kwargs["event_id"])
        user = self.request.user
        qs = event.photos.all()

        if user_is_admin(user):
            return qs

        q_coord = Q(event__coordinator_id=user.id)
        q_public = Q(read_perm=EventPermission.PUBLIC)

        if user_is_img(user):
            q_img = Q(read_perm=EventPermission.IMG)
            return qs.filter(q_coord | q_img | q_public).distinct()
        return qs.filter(q_coord | q_public).distinct()


class PhotoBulkUploadView(generics.CreateAPIView):
    _event = None
    serializer_class = PhotoBulkUploadSerializer
    permission_classes = [PhotoUploadPermission]
    parser_classes = [MultiPartParser, FormParser]

    def get_event(self):
        if not self._event:
            self._event = get_object_or_404(Event, pk=self.kwargs["event_id"])
        return self._event

    def create(self, request, *args, **kwargs):
        event_id = self.kwargs['event_id']
        event = get_object_or_404(Event, pk=event_id)
        serializer = self.get_serializer(
            data=request.data,
            context={'event': event, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        results = serializer.save()

        count = 0
        for r in results:
            if r.get("status") != "created":
                continue
            count += 1
            process_photo_task.delay(r['photo_id'])

        if count > 0:
            create_notification(
                recipient=event.coordinator,
                verb=Notification.NotificationVerb.EVENT_PHOTO_ADDED,
                target_type=Notification.NotificationTarget.EVENT,
                target_id=event.id,
                actor=self.request.user,
                dedupe_key=f"event_add:{event.id}:actor:{self.request.user.id}",
                data={"count": count}
            )

        return Response({"results": results}, status=207)


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


class PhotoSearchView(generics.ListAPIView):
    serializer_class = PhotoListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Photo.objects.all()

        if user_is_admin(user):
            return qs

        if not user.is_authenticated:
            return qs.none()

        q_photographer = Q(photographer=user)
        q_img = Q(read_perm=ReadPerm.IMG)
        q_public = Q(read_perm=ReadPerm.PUBLIC)

        if user_is_img(user):
            return qs.filter(q_photographer | q_img | q_public).distinct()
        return qs.filter(q_photographer | q_public).distinct()

    def list(self, request, *args, **kwargs):
        search_params = request.query_params.dict()

        tags = request.query_params.getlist('tags')
        if tags:
            search_params['tags'] = tags

        serializer = PhotoSearchSerializer(data=search_params)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        base_qs = self.get_queryset()
        search_service = PhotoSearchService(base_qs)
        filtered_qs = search_service.search(**serializer.validated_data)

        serialized = self.get_serializer(filtered_qs, many=True)
        response_data = {
            'count': filtered_qs.count(),
            'results': serialized.data,
        }

        return Response(response_data)
