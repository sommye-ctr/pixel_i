import os
from datetime import timedelta
from io import BytesIO

from PIL import Image, ImageFilter, ImageOps
from django.core.files.base import ContentFile
from django.core.files.images import ImageFile
from django.utils import timezone
from dotenv import load_dotenv
from firebase_admin import storage
from firebase_admin.exceptions import FirebaseError
from rest_framework.exceptions import APIException

load_dotenv()
image_ttl = int(os.getenv("DEFAULT_IMAGE_TTL"))


def pillow_to_content_file(image, filename="img.webp", format="WEBP"):
    buffer = BytesIO()
    image.save(buffer, format=format)
    buffer.seek(0)

    file = ContentFile(buffer.read(), name=filename)
    return file


def download_image_from_firebase(image_path):
    try:
        bucket = storage.bucket()
    except FirebaseError as e:
        raise APIException(f"Storage config error {e}")

    blob = bucket.blob(image_path)
    try:
        d = blob.download_as_bytes()
    except Exception as e:
        raise APIException(f"Error downloading image {e}")
    return BytesIO(d)


def generate_signed_url(path: str, ttl_seconds=image_ttl):
    ttl_seconds = min(image_ttl, ttl_seconds)
    bucket = storage.bucket()
    blob = bucket.blob(path)
    return blob.generate_signed_url(
        expiration=timezone.now() + timedelta(seconds=ttl_seconds),
        method="GET",
    )


def upload_to_storage(photo_id, file: ImageFile, variant="original"):
    try:
        bucket = storage.bucket()
    except FirebaseError as e:
        raise APIException(f"Storage config error {e}")

    try:
        extension = file.name.split(".")[-1].lower()
    except Exception:
        extension = "jpg"

    path = f"media/{photo_id}/{variant}.{extension}"
    blob = bucket.blob(path)

    try:
        file.seek(0)
        blob.upload_from_file(file)
    except FirebaseError as e:
        raise APIException(f"Firebase uploading error {e}")
    except Exception as e:
        raise APIException(f"Unexpected server error during upload {e}")

    return path


def generate_thumbnail_image(image_file, size=(300, 300), blur_radius=10):
    with Image.open(image_file) as img:
        format = img.format
        img = img.convert('RGB')
        img.thumbnail(size, Image.Resampling.LANCZOS)
        img = img.filter(ImageFilter.GaussianBlur(blur_radius))

        return pillow_to_content_file(img, f"thumbnail.{format.lower()}", format.upper())


def _prepare_logo(target_width, logo_path="pixel-i.jpg"):
    with Image.open(logo_path).convert("RGBA") as logo:
        logo = logo.copy()
        logo = logo.convert("L")
        logo = logo.point(lambda x: 255 if x < 50 else 0)

        w, h = logo.size
        margin = 20
        scale = (target_width - margin) / float(w)
        new_size = (target_width, int(h * scale))
        logo = logo.resize(new_size, Image.Resampling.LANCZOS)

        logo = logo.filter(ImageFilter.CONTOUR)
        mask = ImageOps.invert(logo)
        logo_rgba = Image.new("RGBA", mask.size, (255, 255, 255, 0))
        logo_rgba.putalpha(mask)

        return logo_rgba


def generate_watermarked_image(base_image_file):
    with Image.open(base_image_file) as base:
        format = base.format
        base = base.convert("RGBA")
        bw, bh = base.size
        logo_rgba = _prepare_logo(bw)
        lw, lh = logo_rgba.size

        x = (bw - lw) // 2
        y = (bh - lh) // 2

        base.paste(logo_rgba, (x, y), logo_rgba)
        base = base.convert("RGB")
        return pillow_to_content_file(base, f"watermarked.{format.lower()}", format.upper())
