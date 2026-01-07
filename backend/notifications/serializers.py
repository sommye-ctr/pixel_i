from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from notifications.models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    actor = MiniUserSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = [
            "id",
            "actor",
            "verb",
            "target_type",
            "target_id",
            "data",
            "read",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "actor",
            "verb",
            "target_type",
            "target_id",
            "data",
            "created_at",
            "updated_at",
        ]
