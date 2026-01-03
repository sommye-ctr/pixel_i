import os
from datetime import timedelta
from io import BytesIO

import clip
import torch
from PIL import Image
from PIL.ExifTags import TAGS
from django.core.files.base import ContentFile
from django.core.files.images import ImageFile
from django.utils import timezone
from dotenv import load_dotenv
from firebase_admin import storage
from firebase_admin.exceptions import FirebaseError
from rest_framework.exceptions import APIException

from accounts.models import CustomUser
from notifications.models import Notification
from notifications.services import create_notification
from photos.models import PhotoTag

load_dotenv()
image_ttl = int(os.getenv("DEFAULT_IMAGE_TTL"))

CLIP_TAGS = [
    # People & composition
    "single person", "two people", "group photo", "large group", "crowd",
    "audience", "people posing", "candid photo", "selfie", "portrait",
    "side profile", "people walking", "people talking", "people clapping",

    # Stage & structure
    "speaker on stage", "person at podium", "panel discussion",
    "presentation slide", "panel seating", "microphone on stage",
    "stage performance", "award presentation",
    "certificate handover", "trophy presentation",

    # Activities
    "speech", "performance", "dance performance", "music performance",
    "live concert", "question and answer session", "discussion",
    "celebration", "inauguration ceremony", "closing ceremony",

    # Environment
    "indoor event", "outdoor event", "auditorium", "conference hall",
    "classroom", "open ground", "stage lighting",
    "decorated stage", "banner backdrop", "projection screen",

    # Time & lighting
    "daytime event", "night event", "low light", "bright lighting",
    "spotlight on stage", "artificial lighting", "natural lighting",

    # Camera / shot
    "wide angle shot", "close up shot", "medium shot",
    "overhead shot", "side angle shot", "front view", "back view",

    # Mood
    "formal event", "informal gathering", "serious mood",
    "celebratory mood", "energetic atmosphere",
    "crowded atmosphere", "focused audience",

    # College-specific
    "college event", "technical event", "cultural event", "seminar",
    "workshop", "guest lecture", "orientation session",
    "convocation ceremony",

    # Misc
    "people holding certificates", "people holding microphones",
    "people using laptops", "people using mobile phones",
    "applause moment", "group applause"
]


def generate_auto_tag_photo(image_bytes: BytesIO, threshold=0.3):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model, preprocess = clip.load("ViT-B/32", device=device)

    image = Image.open(image_bytes).convert("RGB")
    image_tensor = preprocess(image).unsqueeze(0).to(device)
    tokens = clip.tokenize(CLIP_TAGS).to(device)
    with torch.no_grad():
        image_features = model.encode_image(image_tensor)
        text_features = model.encode_text(tokens)

        image_features = image_features / image_features.norm(dim=-1, keepdim=True)
        text_features = text_features / text_features.norm(dim=-1, keepdim=True)

        similarity = (image_features @ text_features.T)

    scores = similarity[0].cpu().tolist()
    return [CLIP_TAGS[i] for i, score in enumerate(scores) if score >= threshold]


def create_photo_tags(photo, usernames, actor):
    if not usernames:
        return

    users = list(CustomUser.objects.filter(username__in=usernames))
    found_usernames = {u.username for u in users}
    missing = set(usernames) - found_usernames
    if missing:
        from rest_framework.exceptions import ValidationError
        raise ValidationError(
            {"tagged_usernames": [f"Unknown usernames: {', '.join(sorted(missing))}"]}
        )

    already_tagged_ids = set(
        PhotoTag.objects
        .filter(photo=photo, user__in=users)
        .values_list("user_id", flat=True)
    )
    new_users = [u for u in users if u.id not in already_tagged_ids]
    if not new_users:
        return

    PhotoTag.objects.bulk_create(
        [PhotoTag(photo=photo, user=u) for u in new_users]
    )
    for user in new_users:
        create_notification(
            recipient=user,
            actor=actor,
            verb=Notification.NotificationVerb.TAGGED,
            target_type=Notification.NotificationTarget.PHOTO,
            target_id=photo.id,
        )


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
        if variant in ["watermarked", "thumbnail"]:
            blob.make_public()
    except FirebaseError as e:
        raise APIException(f"Firebase uploading error {e}")
    except Exception as e:
        raise APIException(f"Unexpected server error during upload {e}")

    if variant in ["watermarked", "thumbnail"]:
        download_url = blob.public_url
    else:
        download_url = None

    return path, download_url


def generate_thumbnail_image(image_file, size=(300, 300)):
    with Image.open(image_file) as img:
        img_format = img.format
        img = img.convert('RGB')
        img.thumbnail(size, Image.Resampling.LANCZOS)

        return pillow_to_content_file(img, f"thumbnail.{img_format.lower()}", img_format.upper())


def _prepare_logo(target_width, logo_path="pixel-i.png"):
    with Image.open(logo_path).convert("RGBA") as logo:
        w, h = logo.size
        scale = target_width / float(w)
        new_size = (target_width, int(h * scale))
        logo_resized = logo.resize(new_size, Image.Resampling.LANCZOS)
        return logo_resized


def generate_watermarked_image(base_image_file, size=1200):
    with Image.open(base_image_file) as base:
        img_format = base.format
        base = base.convert("RGBA")

        base.thumbnail((size, size), Image.Resampling.LANCZOS)

        bw, bh = base.size
        logo_rgba = _prepare_logo(int(bw * 0.25))
        lw, lh = logo_rgba.size

        padding = 20
        x = bw - lw - padding
        y = bh - lh - padding

        base.paste(logo_rgba, (x, y), logo_rgba)
        base = base.convert("RGB")
        return pillow_to_content_file(base, f"watermarked.{img_format.lower()}", img_format.upper())


def extract_exif_data(image_bytes: BytesIO):
    exif_data = {}

    try:
        image_bytes.seek(0)
        image = Image.open(image_bytes)
        width, height = image.size

        try:
            exif = image.getexif()
            if exif:
                for tag_id, value in exif.items():
                    tag_name = TAGS.get(tag_id, str(tag_id))
                    if isinstance(value, bytes):
                        try:
                            value = value.decode('utf-8', errors='ignore')
                        except:
                            value = str(value)
                    exif_data[tag_name] = str(value)
        except (AttributeError, KeyError):
            pass

        return width, height, exif_data
    except Exception as e:
        # If EXIF extraction fails, still try to get dimensions
        try:
            image_bytes.seek(0)
            image = Image.open(image_bytes)
            width, height = image.size
            return width, height, {}
        except:
            raise APIException(f"Error extracting image metadata: {e}")
