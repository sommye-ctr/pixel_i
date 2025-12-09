from rest_framework import generics, mixins
from rest_framework.generics import get_object_or_404

from engagement.models import Like, Comment
from engagement.permissions import EngagementPermission, IsOwner
from engagement.serializers import LikeSerializer, CommentSerializer
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

    def perform_create(self, serializer):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        serializer.save(photo=photo, user=self.request.user)


class LikeView(BaseEngagementView):
    model = Like
    serializer_class = LikeSerializer

    def get_object(self):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        return get_object_or_404(Like, photo=photo, user=self.request.user)


class CommentView(BaseEngagementView):
    model = Comment
    serializer_class = CommentSerializer
