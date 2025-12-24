from django.urls import path, include
from rest_framework.routers import DefaultRouter

from events.views import EventsView

router = DefaultRouter()
router.register("", EventsView, basename="events")

urlpatterns = [
    path('', include(router.urls))
]
