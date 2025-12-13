from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import ValidationError

from accounts.models import CustomUser
from accounts.serializers import MiniUserSerializer
from photos.models import Photo, PhotoTag, PhotoShare
from photos.permissions import is_admin_or_photographer
from photos.services import upload_to_storage, generate_signed_url


# downloads and views only for photographer
class PhotoSerializer(serializers.ModelSerializer):
    tagged_users = MiniUserSerializer(many=True, read_only=True)
    original_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'meta', 'photographer', 'event', 'tagged_users', 'downloads', 'views',
            'read_perm', 'share_perm', 'original_url', 'thumbnail_url', 'likes_count'
        ]
        read_only_fields = fields

    SENSITIVE = ['downloads', 'views', 'read_perm', 'share_perm']

    def get_likes_count(self, obj: Photo):
        return obj.likes.count()

    def get_original_url(self, obj):
        return generate_signed_url(obj.original_path)

    def get_thumbnail_url(self, obj):
        return generate_signed_url(obj.thumbnail_path)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        user = getattr(self.context.get('request'), 'user', None)

        can_view = False
        if not user or not user.is_authenticated:
            can_view = False

        if is_admin_or_photographer(user, instance):
            can_view = True

        if not can_view:
            for f in self.SENSITIVE:
                data.pop(f, None)
        return data


class PhotoListSerializer(serializers.ModelSerializer):
    thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'photographer', 'thumbnail_url'
        ]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        return generate_signed_url(obj.thumbnail_path)


class PhotoWriteSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(write_only=True, required=True)
    tagged_usernames = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False,
    )
    tagged_users = MiniUserSerializer(many=True, read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'meta', 'read_perm', 'share_perm', 'event',
            'tagged_usernames', 'tagged_users', 'image'
        ]

    def create(self, validated_data):
        tagged_usernames = validated_data.pop('tagged_usernames', [])
        request = self.context.get('request')
        photographer = getattr(request, 'user', None)
        image_file = validated_data.pop('image', None)

        with transaction.atomic():
            photo = Photo.objects.create(
                photographer=photographer,
                **validated_data,
            )
            photo.original_path = upload_to_storage(photo.id, image_file)
            photo.save(update_fields=['original_path'])
            self._create_tags(photo, tagged_usernames)
        return photo

    def update(self, instance, validated_data):
        tagged_usernames = validated_data.pop('tagged_usernames', None)
        print(f"TAGGED {tagged_usernames}")

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if tagged_usernames is not None:
            PhotoTag.objects.filter(photo=instance).delete()
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

        PhotoTag.objects.bulk_create(
            [PhotoTag(photo=photo, user=u) for u in users]
        )


class PhotoShareSerializer(serializers.ModelSerializer):
    share_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = PhotoShare
        fields = ['token', 'photo', 'variant_key', 'expires_at', 'share_url']
        read_only_fields = ['token', 'photo']

    def validate_expires_at(self, value):
        if value is None:
            raise ValidationError(f"expires_at field is required")
        if value <= timezone.now():
            raise ValidationError(f"Expiry {value} need to be greater than current time")
        return value

    def get_share_url(self, obj: PhotoShare):
        if obj.variant_key == 'W':
            path = obj.photo.watermarked_path
        else:
            path = obj.photo.original_path

        remaining = None
        if obj.expires_at is not None:
            now = timezone.now()
            remaining = int((obj.expires_at - now).total_seconds())
            if remaining <= 0:
                return None

        return generate_signed_url(path, remaining)
