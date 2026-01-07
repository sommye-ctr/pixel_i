from django.urls import path

from notifications.views import NotificationListView, NotificationUpdateView

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('<uuid:id>/', NotificationUpdateView.as_view(), name='notification-update'),
]
