from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from engagement.models import Like, Comment
from photos.serializers import PhotoReadSerializer


class LikeSerializer(serializers.ModelSerializer):
    photo = PhotoReadSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['photo', 'created_at']


class CommentSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'user', 'created_at', 'content']
