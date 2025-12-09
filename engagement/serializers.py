from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from engagement.models import Like


class LikeSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['user', 'timestamp']
