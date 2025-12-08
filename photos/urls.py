from django.urls import path, include
from rest_framework.routers import DefaultRouter

from photos.views import PhotoView, PhotoShareCreateView, PhotoShareDetailView

router = DefaultRouter()
router.register('', PhotoView, 'photos')
urlpatterns = [
    path('', include(router.urls)),
    path(
        "<uuid:photo_id>/share/",
        PhotoShareCreateView.as_view(),
        name="photo-share-create",
    ),
    path(
        'share/<uuid:token>/',
        PhotoShareDetailView.as_view(),
        name="photo-share-detail",
    )
]
