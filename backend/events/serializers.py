from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from events.models import Event
from events.permissions import can_write_to_event
from photos.serializers import PhotoMiniSerializer


class EventReadSerializer(serializers.ModelSerializer):
    images_count = serializers.SerializerMethodField()
    cover_photo = serializers.SerializerMethodField()
    coordinator = MiniUserSerializer(read_only=True)
    can_write = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Event
        fields = ['id', 'title', 'read_perm', 'can_write', 'coordinator', 'images_count', 'cover_photo', 'created_at']

    def get_images_count(self, obj: Event):
        return obj.photos.count()

    def get_cover_photo(self, obj: Event):
        first_photo = obj.photos.order_by('timestamp').first()
        if not first_photo:
            return None
        return PhotoMiniSerializer(first_photo, context=self.context).data

    def get_can_write(self, obj: Event):
        request = self.context.get('request')
        return can_write_to_event(request.user, obj) if request else False


class EventWriteSerializer(serializers.ModelSerializer):
    coordinator = MiniUserSerializer(read_only=True)

    class Meta:
        model = Event
        fields = ['id', 'title', 'read_perm', 'write_perm', 'coordinator']

    def create(self, validated_data):
        user = self.context['request'].user
        return Event.objects.create(coordinator=user, **validated_data)
