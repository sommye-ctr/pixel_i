from django.urls import path

from engagement.views import LikeView, CommentView

urlpatterns = [
    path('photos/<uuid:photo_id>/likes/', LikeView.as_view(), name='photo-likes'),
    path('photos/<uuid:photo_id>/comments/', CommentView.as_view(), name='photo-comments'),
    path("photos/<uuid:photo_id>/comments/<uuid:pk>/", CommentView.as_view(), name="photo-comments-destroy"),

]
