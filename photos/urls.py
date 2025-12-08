from django.urls import path, include
from rest_framework.routers import DefaultRouter

from photos.views import PhotoView

router = DefaultRouter()
router.register('', PhotoView, 'photos')
urlpatterns = [
    path('', include(router.urls))
]
