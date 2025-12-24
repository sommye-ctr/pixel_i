from django.contrib import admin

from photos.models import Photo, PhotoTag, PhotoShare

admin.site.register(Photo)
admin.site.register(PhotoTag)
admin.site.register(PhotoShare)