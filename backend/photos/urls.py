from django.urls import path, include
from rest_framework.routers import DefaultRouter

from photos.views import PhotoView, PhotoShareCreateView, PhotoShareDetailView, PhotoSearchView, PhotosTaggedInView

router = DefaultRouter()
router.register('', PhotoView, 'photos')
urlpatterns = [
    path(
        "search/",
        PhotoSearchView.as_view(),
        name="photo-search",
    ),
    path(
        "<uuid:photo_id>/share/",
        PhotoShareCreateView.as_view(),
        name="photo-share-create",
    ),
    path(
        'share/<uuid:token>/',
        PhotoShareDetailView.as_view(),
        name="photo-share-detail",
    ),
    path('photos-tagged-in/', PhotosTaggedInView.as_view(), name='photos_tagged_in'),
    path('', include(router.urls)),
]
