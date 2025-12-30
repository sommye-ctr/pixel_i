from django.urls import path, include
from rest_framework.routers import DefaultRouter

from events.views import EventsView
from photos.views import EventPhotosView

router = DefaultRouter()
router.register("", EventsView, basename="events")

urlpatterns = [
    path('', include(router.urls)),
    path('<uuid:event_id>/photos/', EventPhotosView.as_view(), name='event-photos')
]
