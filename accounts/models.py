import secrets
import uuid
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Model
from django.utils import timezone


class Role(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=30, unique=True, blank=False, null=False)  # admin/public/img

    def __str__(self):
        return self.title


class CustomUser(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    email = models.EmailField(unique=True)
    name = models.CharField(max_length=180, blank=False, null=False)
    profile_pic = models.URLField(blank=True, null=True)
    batch = models.CharField(max_length=32, blank=True, null=True)
    department = models.CharField(max_length=120, blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    role = models.ForeignKey(Role, on_delete=models.PROTECT, null=False)  # roles cannot be deleted

    def save(self, *args, **kwargs, ):
        if not self.role_id:
            self.role = Role.objects.get(title="public")
        super().save(*args, **kwargs)

    def __str__(self):
        return self.username


class EmailOTP(models.Model):
    PURPOSE_EMAIL_VERIFICATION = "email_verification"
    PURPOSE_PASSWORD_RESET = "password_reset"

    PURPOSE_CHOICES = [
        (PURPOSE_EMAIL_VERIFICATION, "Email verification"),
        (PURPOSE_PASSWORD_RESET, "Password reset"),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="email_otps")
    code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES, default=PURPOSE_EMAIL_VERIFICATION)
    created_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveIntegerField(default=0)

    class Meta:
        indexes = [
            models.Index(fields=["user", "purpose", "is_used"]),
        ]

    def is_expired(self):
        return timezone.now() >= self.expires_at

    @classmethod
    def generate_code(cls):
        # cryptographically secure 6-digit code
        return f"{secrets.randbelow(1000000):06d}"

    @classmethod
    def create_for_user(cls, user, ttl_minutes, purpose=PURPOSE_EMAIL_VERIFICATION):
        cls.objects.filter(
            user=user,
            purpose=purpose,
            is_used=False,
        ).delete()

        code = cls.generate_code()
        now = timezone.now()
        return cls.objects.create(
            user=user,
            code=code,
            purpose=purpose,
            expires_at=now + timedelta(minutes=ttl_minutes),
        )
