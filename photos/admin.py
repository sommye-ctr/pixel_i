from django.contrib import admin

from photos.models import Photo, PhotoTags, PhotoShares

admin.site.register(Photo)
admin.site.register(PhotoTags)
admin.site.register(PhotoShares)