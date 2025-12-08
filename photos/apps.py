import firebase_admin
from django.apps import AppConfig
from firebase_admin import credentials


class PhotosConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'photos'

    def ready(self):
        if not firebase_admin._apps:
            cred = credentials.Certificate('pixel-i.json')
            firebase_admin.initialize_app(cred)
