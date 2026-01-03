from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import ValidationError

from accounts.serializers import MiniUserSerializer
from photos.models import Photo, PhotoShare
from photos.permissions import is_admin_or_photographer
from photos.services import generate_signed_url, create_photo_tags, upload_to_storage


class PhotoMiniSerializer(serializers.ModelSerializer):
    thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = Photo
        fields = [
            'id', 'thumbnail_url', 'width', 'height'
        ]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        return generate_signed_url(obj.thumbnail_path)


class PhotoBulkUploadSerializer(serializers.Serializer):
    images = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=True,
        min_length=1,
        max_length=20,
    )
    metadata = serializers.JSONField(write_only=True, required=True)

    def validate(self, attrs):
        images = attrs.get('images', [])
        metadata = attrs.get('metadata', [])
        if not isinstance(metadata, list):
            raise ValidationError("Metadata must be a list of objects")
        if len(metadata) != len(images):
            raise ValidationError("Metadata length must match images length")

        meta_map = {}
        for meta in metadata:
            if not isinstance(meta, dict) or "client_id" not in meta:
                raise ValidationError("Each metadata entry must have a client_id field")
            meta_map[meta["client_id"]] = meta

        attrs['meta_map'] = meta_map
        return attrs

    def create(self, validated_data):
        req = self.context.get("request")
        event = self.context.get("event")

        images = validated_data.get('images', [])
        meta_map = validated_data.get('meta_map')
        res = []

        for image in images:
            client_id = image.name
            meta = meta_map.get(client_id)
            if not meta:
                res.append({
                    "client_id": client_id,
                    "status": "error",
                    "error": "Missing metadata"
                })
                continue

            serializer = PhotoWriteSerializer(
                data={
                    "event": event.id,
                    "image": image,
                    **meta,
                },
                context={"request": req},
            )
            if not serializer.is_valid():
                res.append({
                    "client_id": client_id,
                    "status": "error",
                    "error": serializer.errors
                })
                continue

            try:
                photo = serializer.save()
                res.append({
                    "client_id": client_id,
                    "photo_id": photo.id,
                    "status": "created"
                })
            except ValidationError as e:
                res.append({
                    "client_id": client_id,
                    "status": "error",
                    "error": e.detail
                })
            except Exception as e:
                res.append({
                    "client_id": client_id,
                    "status": "error",
                    "error": str(e)
                })

        return res


# downloads and views only for photographer
class PhotoReadSerializer(serializers.ModelSerializer):
    tagged_users = MiniUserSerializer(many=True, read_only=True)
    original_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField(read_only=True)
    is_liked = serializers.SerializerMethodField(read_only=True)
    photographer = MiniUserSerializer(read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'meta', 'photographer', 'event', 'tagged_users', 'downloads', 'views', 'auto_tags',
            'user_tags', 'share_perm', 'original_url', 'thumbnail_url', 'likes_count', 'width', 'height', 'is_liked'
        ]
        read_only_fields = fields

    SENSITIVE = ['downloads', 'views', 'read_perm', 'share_perm']

    def get_is_liked(self, obj: Photo):
        user = getattr(self.context.get('request'), 'user', None)
        if not user or not user.is_authenticated:
            return False
        return obj.likes.filter(user=user).exists()

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
    photographer = MiniUserSerializer(read_only=True)

    class Meta:
        model = Photo
        fields = [
            'id', 'timestamp', 'photographer', 'thumbnail_url', 'width', 'height'
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
            'tagged_usernames', 'tagged_users', 'image', 'width', 'height', 'user_tags'
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
            create_photo_tags(photo, usernames=tagged_usernames, actor=photographer)

        try:
            photo.original_path = upload_to_storage(photo.id, image_file)
            photo.save(update_fields=['original_path'])
        except Exception:
            photo.delete()
            raise serializers.ValidationError(
                "Image upload failed"
            )

        return photo

    def update(self, instance, validated_data):
        tagged_usernames = validated_data.pop('tagged_usernames', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if tagged_usernames is not None:
            create_photo_tags(instance, usernames=tagged_usernames, actor=self.context.get("request").get("user"))

        return instance


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
