from rest_framework import generics, mixins
from rest_framework.generics import get_object_or_404

from engagement.models import Like, Comment
from engagement.permissions import EngagementPermission, IsOwner
from engagement.serializers import LikeSerializer, CommentSerializer
from photos.models import Photo


class BaseEngagementPermission(generics.GenericAPIView,
                               mixins.CreateModelMixin,
                               mixins.DestroyModelMixin):
    def get_permissions(self):
        if self.request.method == 'POST':
            return [EngagementPermission()]
        else:
            return [IsOwner()]

    def post(self, request, *args, **kwargs):
        return self.create(request, *args, **kwargs)

    def delete(self, request, *args, **kwargs):
        return self.destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        photo_id = self.kwargs['photo_id']
        photo = get_object_or_404(Photo, pk=photo_id)
        serializer.save(photo=photo, user=self.request.user)


class LikeView(BaseEngagementPermission):
    queryset = Like.objects.all()
    serializer_class = LikeSerializer


class CommentView(BaseEngagementPermission):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
