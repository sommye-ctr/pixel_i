from rest_framework import serializers

from accounts.serializers import MiniUserSerializer
from engagement.models import Like, Comment
from photos.serializers import PhotoReadSerializer


class LikeSerializer(serializers.ModelSerializer):
    photo = PhotoReadSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['photo', 'created_at']


class TopLevelCommentSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)
    child_count = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'user', 'created_at', 'content', 'child_count']

    def get_child_count(self, obj):
        return obj.child_comments.count()


class CommentSerializer(serializers.ModelSerializer):
    user = MiniUserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'user', 'created_at', 'content', 'parent_comment']

    def validate_parent_comment(self, value):
        if value is not None and value.parent_comment is not None:
            raise serializers.ValidationError(
                "Replies to replies are not allowed. Only one level of nesting is permitted.")
        return value
