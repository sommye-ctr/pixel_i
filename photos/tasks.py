from celery import shared_task

from photos.models import Photo
from utils.photo_utils import generate_watermarked_image, generate_thumbnail_image, upload_to_storage, \
    download_image_from_firebase


@shared_task
def generate_image_variants_task(photo_id):
    photo = Photo.objects.get(id=photo_id)

    original_img = download_image_from_firebase(photo.original_path)

    watermarked = generate_watermarked_image(original_img)
    thumbnail = generate_thumbnail_image(original_img)

    wp = tp = None
    try:
        wp = upload_to_storage(photo_id, watermarked, "watermarked")
        tp = upload_to_storage(photo_id, thumbnail, 'thumbnail')
    except Exception:
        if wp:
            photo.watermarked_path = wp

        if tp:
            photo.thumbnail_path = tp

        photo.status = Photo.PhotoStatus.FAILED
        photo.save(update_fields=["watermarked_path", "thumbnail_path", "status"])
        raise
    else:
        photo.watermarked_path = wp
        photo.thumbnail_path = tp
        photo.status = Photo.PhotoStatus.COMPLETED
        photo.save(update_fields=["watermarked_path", "thumbnail_path", "status"])
