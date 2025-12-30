from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from events.models import Event
from photos.serializers import PhotoMiniSerializer


class EventReadSerializer(serializers.ModelSerializer):
    images_count = serializers.SerializerMethodField()
    cover_photo = serializers.SerializerMethodField()
    coordinator = MiniUserSerializer(read_only=True)

    class Meta:
        model = Event
        fields = ['id', 'title', 'read_perm', 'coordinator', 'images_count', 'cover_photo', 'created_at']

    def get_images_count(self, obj: Event):
        return obj.photos.count()

    def get_cover_photo(self, obj: Event):
        first_photo = obj.photos.order_by('timestamp').first()
        if not first_photo:
            return None
        return PhotoMiniSerializer(first_photo, context=self.context).data


class EventWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['title', 'read_perm', 'write_perm']

    def create(self, validated_data):
        user = self.context['request'].user
        return Event.objects.create(coordinator=user, **validated_data)
