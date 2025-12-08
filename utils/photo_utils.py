from django.core.files.images import ImageFile
from firebase_admin import storage
from firebase_admin.exceptions import FirebaseError
from rest_framework.exceptions import APIException

from photos.models import Photo


def upload_to_storage(photo: Photo, file: ImageFile):
    try:
        bucket = storage.bucket()
    except FirebaseError as e:
        raise APIException(f"Storage config error {e}")

    try:
        extension = file.name.split(".")[-1].lower()
    except Exception:
        extension = "jpg"

    path = f"media/{photo.id}/original.{extension}"
    blob = bucket.blob(path)

    try:
        file.seek(0)
        blob.upload_from_file(file)
    except FirebaseError as e:
        raise APIException(f"Firebase uploading error {e}")
    except Exception as e:
        raise APIException(f"Unexpected server error during upload {e}")

    photo.original_path = path
    return photo
