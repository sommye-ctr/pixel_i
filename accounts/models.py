import secrets
import uuid
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Model
from django.utils import timezone

from pixel_i import settings


class Role(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=30, unique=True, blank=False, null=False)  # admin/public/img

    def __str__(self):
        return self.title


class OAuthUser(models.Model):
    PROVIDER_CHOICES = [
        ("omniport", "Omniport"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="oauth_accounts")
    provider = models.CharField(max_length=50, choices=PROVIDER_CHOICES)
    profile_json = models.JSONField(blank=True, null=True)
    provider_user_id = models.CharField(max_length=255)

    access_token = models.TextField(blank=True, null=True)
    refresh_token = models.TextField(blank=True, null=True)
    access_token_expires_at = models.DateTimeField(blank=True, null=True)
    scopes = models.CharField(max_length=255, blank=True, null=True)

    revoked = models.BooleanField(default=False)
    last_synced = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["provider", "provider_user_id"],
                name="uq_oauth_provider_provideruserid"
            ),
            models.UniqueConstraint(
                fields=["user", "provider"],
                name="uq_oauth_user_provider"
            ),
        ]
        indexes = [
            models.Index(fields=["provider", "provider_user_id"]),
            models.Index(fields=["user"]),
        ]

    def is_access_token_expired(self):
        if not self.access_token_expires_at:
            return True
        return timezone.now() >= self.access_token_expires_at

    def set_token_data(self, access_token, refresh_token=None, expires_in=None, scopes=None):
        self.access_token = access_token
        if refresh_token is not None:
            self.refresh_token = refresh_token
        if expires_in:
            self.access_token_expires_at = timezone.now() + timedelta(seconds=expires_in)
        if scopes is not None:
            self.scopes = scopes
        self.save(update_fields=["access_token", "refresh_token", "access_token_expires_at", "scopes", "updated_at"])


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
