import logging

from celery import shared_task

from photos.models import Photo
from photos.services import (
    generate_watermarked_image,
    generate_thumbnail_image,
    upload_to_storage,
    download_image_from_firebase,
    generate_auto_tag_photo,
    extract_exif_data
)

logger = logging.getLogger(__name__)


@shared_task
def process_photo_task(photo_id):
    photo = Photo.objects.get(id=photo_id)
    processing_errors = {}

    try:
        original_img = download_image_from_firebase(photo.original_path)
    except Exception as e:
        logger.error(f"Photo {photo_id}: Failed to download original image - {str(e)}")
        photo.status = Photo.PhotoStatus.FAILED
        photo.processing_errors = {"download": str(e)}
        photo.save(update_fields=["status", "processing_errors"])
        raise

    try:
        watermarked = generate_watermarked_image(original_img)
        thumbnail = generate_thumbnail_image(original_img)

        wp, watermarked_url = upload_to_storage(photo_id, watermarked, "watermarked")
        tp, thumbnail_url = upload_to_storage(photo_id, thumbnail, 'thumbnail')

        photo.watermarked_url = watermarked_url
        photo.thumbnail_url = thumbnail_url
        logger.info(f"Photo {photo_id}: Successfully generated image variants")
    except Exception as e:
        logger.error(f"Photo {photo_id}: Failed to generate image variants - {str(e)}")
        processing_errors["variants"] = str(e)

    try:
        original_img.seek(0)
        tags = generate_auto_tag_photo(original_img)
        photo.auto_tags = tags
        logger.info(f"Photo {photo_id}: Successfully generated auto tags")
    except Exception as e:
        logger.error(f"Photo {photo_id}: Failed to generate auto tags - {str(e)}")
        processing_errors["tagging"] = str(e)

    try:
        original_img.seek(0)
        width, height, exif_data = extract_exif_data(original_img)
        photo.width = width
        photo.height = height
        photo.meta = exif_data
        logger.info(f"Photo {photo_id}: Successfully extracted metadata")
    except Exception as e:
        logger.error(f"Photo {photo_id}: Failed to extract metadata - {str(e)}")
        processing_errors["metadata"] = str(e)

    if processing_errors:
        photo.status = Photo.PhotoStatus.COMPLETED
        photo.processing_errors = processing_errors
        logger.warning(f"Photo {photo_id}: Partial processing - completed with errors: {processing_errors}")
    else:
        photo.status = Photo.PhotoStatus.COMPLETED
        photo.processing_errors = {}
        logger.info(f"Photo {photo_id}: Successfully completed all processing steps")

    photo.save(update_fields=[
        "watermarked_url",
        "thumbnail_url",
        "auto_tags",
        "width",
        "height",
        "meta",
        "status",
        "processing_errors"
    ])
