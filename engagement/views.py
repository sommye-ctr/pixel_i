from rest_framework import generics, mixins
from rest_framework.generics import get_object_or_404

from engagement.models import Like
from engagement.permissions import LikePermission, IsOwner
from engagement.serializers import LikeSerializer
from photos.models import Photo


class LikeView(generics.GenericAPIView,
               mixins.CreateModelMixin,
               mixins.DestroyModelMixin):
    model = Like
    serializer_class = LikeSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [LikePermission()]
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
