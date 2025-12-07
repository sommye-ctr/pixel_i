from rest_framework import serializers

from accounts.models import CustomUser
from photos.models import Photo


class TaggedUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'name']


# downloads and views only for photographer
class PhotoSerializer(serializers.ModelSerializer):
    tagged_users = TaggedUserSerializer(many=True, read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'meta', 'photographer', 'event',
            'original_path', 'thumbnail_path', 'watermarked_path',
            'tagged_users'
        ]
        read_only_fields = fields
