from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from events.models import Event
from photos.services import generate_signed_url


class EventReadSerializer(serializers.ModelSerializer):
    images_count = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    coordinator = MiniUserSerializer(read_only=True)

    class Meta:
        model = Event
        fields = ['id', 'title', 'read_perm', 'coordinator', 'images_count', 'image_url']

    def get_images_count(self, obj:Event):
        return obj.photos.count()

    def get_image_url(self, obj:Event):
        first_photo = obj.photos.order_by('timestamp').first()
        if first_photo:
            return generate_signed_url(first_photo.thumbnail_path)
        return None


class EventWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['title', 'read_perm', 'write_perm']

    def create(self, validated_data):
        user = self.context['request'].user
        return Event.objects.create(coordinator=user, **validated_data)
