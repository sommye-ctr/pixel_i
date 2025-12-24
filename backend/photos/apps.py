import os

import firebase_admin
from django.apps import AppConfig
from dotenv import load_dotenv
from firebase_admin import credentials


class PhotosConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'photos'

    def ready(self):
        load_dotenv()
        if not firebase_admin._apps:
            cred = credentials.Certificate('pixel-i.json')
            firebase_admin.initialize_app(cred, {
                'storageBucket': os.getenv('FIREBASE_BUCKET_LINK')
            })
