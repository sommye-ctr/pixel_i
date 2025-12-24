import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "pixel_i.settings")
app = Celery("pixel_i")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
