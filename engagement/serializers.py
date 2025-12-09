from rest_framework import serializers

from engagement.models import Like
from photos.serializers import TaggedUserSerializer


class LikeSerializer(serializers.ModelSerializer):
    user = TaggedUserSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['user', 'timestamp']
