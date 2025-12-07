from rest_framework import serializers

from accounts.models import CustomUser
from photos.models import Photo, PhotoTags


class TaggedUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['username']


class PhotoTagSerializer(serializers.ModelSerializer):
    user = TaggedUserSerializer(read_only=True)

    class Meta:
        model = PhotoTags
        fields = ['user']


# downloads and views only for photographer
class PhotoSerializer(serializers.ModelSerializer):
    tagged_users = PhotoTagSerializer(many=True, read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'meta', 'photographer', 'event',
            'original_path', 'thumbnail_path', 'watermarked_path',
            'tagged_users'
        ]
        read_only_fields = fields


class PhotoListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Photo
        fields = [
            'id', 'thumbnail_path', 'timestamp', 'photographer'
        ]
        read_only_fields = fields


class PhotoWriteSerializer(serializers.ModelSerializer):
    tagged_usernames = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False,
    )
    tagged_users = PhotoTagSerializer(many=True, read_only=True)

    class Meta:
        model = Photo
        fields = [
            'timestamp', 'meta', 'read_perm', 'share_perm', 'event',
            'tagged_usernames', 'tagged_users'
        ]

    def create(self, validated_data):
        tagged_usernames = validated_data.pop('tagged_usernames', [])
        request = self.context.get('request')
        photographer = getattr(request, 'user', None)

        photo = Photo.objects.create(
            photographer=photographer,
            **validated_data,
        )

        self._create_tags(photo, tagged_usernames)
        return photo

    def update(self, instance, validated_data):
        tagged_usernames = validated_data.pop('tagged_usernames', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if tagged_usernames is not None:
            PhotoTags.objects.filter(photo=instance).delete()
            self._create_tags(instance, tagged_usernames)

        return instance

    def _create_tags(self, photo, usernames):
        if not usernames:
            return

        users = list(CustomUser.objects.filter(username__in=usernames))
        found_usernames = {u.username for u in users}
        missing = set(usernames) - found_usernames
        if missing:
            from rest_framework.exceptions import ValidationError
            raise ValidationError(
                {"tagged_usernames": [f"Unknown usernames: {', '.join(sorted(missing))}"]}
            )

        PhotoTags.objects.bulk_create(
            [PhotoTags(photo=photo, user=u) for u in users]
        )
