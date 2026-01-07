from rest_framework import generics, permissions
from rest_framework.response import Response

from notifications.models import Notification
from notifications.serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Notification.objects.filter(recipient=user)

        read_param = self.request.query_params.get("read")
        if read_param is not None:
            read_lower = read_param.lower()
            if read_lower in ("true", "1", "t", "yes", "y"):
                qs = qs.filter(read=True)
            elif read_lower in ("false", "0", "f", "no", "n"):
                qs = qs.filter(read=False)

        ordering_param = self.request.query_params.get("ordering")
        if ordering_param in ("created_at", "-created_at"):
            qs = qs.order_by(ordering_param)
        else:
            qs = qs.order_by("-created_at")
        return qs


class NotificationUpdateView(generics.UpdateAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = "id"

    def get_queryset(self):
        user = self.request.user
        return Notification.objects.filter(recipient=user)

    def update(self, request, *args, **kwargs):
        notification = self.get_object()
        read_value = request.data.get("read")

        if read_value is not None:
            notification.read = bool(read_value)
            notification.save(update_fields=["read"])

        serializer = self.get_serializer(notification)
        return Response(serializer.data)
