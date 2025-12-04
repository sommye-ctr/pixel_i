from rest_framework import serializers

from events.models import Event


class EventReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['id', 'title', 'read_perm', 'coordinator']


class EventWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['title', 'read_perm', 'write_perm']

    def create(self, validated_data):
        user = self.context['request'].user
        return Event.objects.create(coordinator=user, **validated_data)
