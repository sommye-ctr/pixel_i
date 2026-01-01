from django.urls import path, include
from rest_framework.routers import DefaultRouter

from events.views import EventsView
from photos.views import EventPhotosView, PhotoBulkUploadView

router = DefaultRouter()
router.register("", EventsView, basename="events")

urlpatterns = [
    path('', include(router.urls)),
    path('<uuid:event_id>/photos/', EventPhotosView.as_view(), name='event-photos'),
    path('<uuid:event_id>/photos/bulk-upload/', PhotoBulkUploadView.as_view(), name='event-photos-bulk-upload'),
]
