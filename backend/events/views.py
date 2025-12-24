from django.db.models import Q
from rest_framework import viewsets, permissions

from events.models import Event
from events.permissions import user_is_admin, CreateEventPermission, IsCoordinator, RetrieveEventPermission, \
    EventPermission, user_is_img
from events.serializers import EventWriteSerializer, EventReadSerializer


class EventsView(viewsets.ModelViewSet):
    queryset = Event.objects.all()

    def get_serializer_class(self):
        if self.action in ["create", 'update', 'partial_update']:
            return EventWriteSerializer
        return EventReadSerializer

    def get_permissions(self):
        if user_is_admin(self.request.user):
            return [permissions.IsAuthenticated()]

        if self.action == "create":
            return [CreateEventPermission()]
        elif self.action in ("destroy", "update", "partial_update"):
            return [permissions.IsAuthenticated(), IsCoordinator()]
        elif self.action == "retrieve":
            return [permissions.IsAuthenticated(), RetrieveEventPermission()]
        elif self.action == "list":
            return [permissions.IsAuthenticated()]

        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        if self.action != "list" or user_is_admin(user):
            return qs

        if not user.is_authenticated:
            return qs.none()

        q_coord = Q(coordinator_id=user.id)
        q_img = Q(read_perm=EventPermission.IMG)
        q_public = Q(read_perm=EventPermission.PUBLIC)

        if user_is_img(user):
            return qs.filter(q_coord | q_img | q_public).distinct()
        return qs.filter(q_coord | q_public).distinct()
