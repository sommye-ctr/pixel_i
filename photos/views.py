from rest_framework import generics

from photos.models import Photo
from photos.permissions import PhotoReadPermission
from photos.serializers import PhotoSerializer


class PhotoDetailView(generics.RetrieveAPIView):
    queryset = Photo.objects.all()
    serializer_class = PhotoSerializer
    permission_classes = [PhotoReadPermission]
