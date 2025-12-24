from django.db import IntegrityError
from rest_framework import generics, mixins
from rest_framework.exceptions import ValidationError
from rest_framework.generics import get_object_or_404

from engagement.models import Like, Comment
from engagement.permissions import EngagementPermission, IsOwner
from engagement.serializers import LikeSerializer, CommentSerializer
from notifications.models import Notification
from notifications.services import create_notification
from photos.models import Photo


class BaseEngagementView(generics.GenericAPIView,
                         mixins.CreateModelMixin,
                         mixins.DestroyModelMixin,
                         mixins.ListModelMixin):
    def get_permissions(self):
        if self.request.method == 'DELETE':
            return [IsOwner()]
        else:
            return [EngagementPermission()]

    def get(self, request, *args, **kwargs):
        return self.list(request, *args, **kwargs)

    def post(self, request, *args, **kwargs):
        return self.create(request, *args, **kwargs)

    def delete(self, request, *args, **kwargs):
        return self.destroy(request, *args, **kwargs)

    def get_queryset(self):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        return photo.likes.all() if self.model is Like else photo.comments.all()


class LikeView(BaseEngagementView):
    model = Like
    serializer_class = LikeSerializer

    def get_object(self):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        return get_object_or_404(Like, photo=photo, user=self.request.user)

    def perform_create(self, serializer):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        try:
            serializer.save(photo=photo, user=self.request.user)
        except IntegrityError:
            raise ValidationError({"detail": "You have already liked this photo!"})

        create_notification(
            recipient=photo.photographer,
            verb=Notification.NotificationVerb.LIKED,
            target_type=Notification.NotificationTarget.PHOTO,
            target_id=photo.id,
            actor=self.request.user,
            dedupe_key=f"like:{self.request.user.id}:{photo_id}"
        )


class CommentView(BaseEngagementView):
    model = Comment
    serializer_class = CommentSerializer

    def perform_create(self, serializer):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        serializer.save(photo=photo, user=self.request.user)

        create_notification(
            recipient=photo.photographer,
            verb=Notification.NotificationVerb.COMMENTED,
            target_type=Notification.NotificationTarget.PHOTO,
            target_id=photo.id,
            actor=self.request.user,
        )
