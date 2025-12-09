from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from engagement.models import Like, Comment


class LikeSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['user', 'timestamp']


class CommentSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'user', 'timestamp', 'content']
