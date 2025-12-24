from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from accounts.errors import OTPDeliveryError
from accounts.models import EmailOTP
from accounts.services import send_otp_email
from utils.auth_utils import get_otp_max_attempts, get_otp_cooldown, get_otp_ttl

User = get_user_model()


class MiniUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username']


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ("id", "username", "email", "password", "name")
        read_only_fields = ("id",)

    def validate_email(self, v):
        if User.objects.filter(email__iexact=v).exists():
            raise serializers.ValidationError("Email already registered.")
        return v.lower()

    def create(self, validated_data):
        pwd = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(pwd)
        user.is_active = False  # not active till verified by email
        user.save()
        return user


class EmailVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=6)

    def validate(self, attrs):
        email = attrs.get("email")
        otp = attrs.get("otp")

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError("No user with this email.")
        otp_obj = (
            EmailOTP.objects.filter(
                user=user,
                purpose=EmailOTP.PURPOSE_EMAIL_VERIFICATION,
                is_used=False,
            )
            .order_by("-created_at")
            .first()
        )
        if not otp_obj:
            raise serializers.ValidationError({"otp": "No active OTP found. Request a new one."})

        if otp_obj.attempts >= get_otp_max_attempts():
            raise serializers.ValidationError({"otp": "Too many attempts. Request a new OTP."})

        if otp_obj.is_expired():
            raise serializers.ValidationError({"otp": "OTP has expired. Request a new one."})

        if otp_obj.code != otp:
            otp_obj.attempts += 1
            otp_obj.save(update_fields=["attempts"])
            raise serializers.ValidationError({"otp": "Invalid OTP."})

        self.context["user"] = user
        self.context["otp"] = otp_obj
        return attrs

    def create(self, validated_data):
        user = self.context["user"]
        otp = self.context["otp"]

        otp.is_used = True
        otp.save(update_fields=["is_used"])

        user.is_active = True
        user.save(update_fields=["is_active"])

        return validated_data

    def save(self, **kwargs):
        user = self.context['user']
        return user


class ResendEmailOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        try:
            user = User.objects.get(email=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("No user with this email.")

        if getattr(user, "is_active", False):
            raise serializers.ValidationError("Email is already verified.")

        self.context["user"] = user
        return value

    def create(self, validated_data):
        user = self.context["user"]
        now = timezone.now()

        last_otp = (
            EmailOTP.objects.filter(
                user=user,
                purpose=EmailOTP.PURPOSE_EMAIL_VERIFICATION,
            )
            .order_by("-created_at")
            .first()
        )

        if last_otp and last_otp.created_at > now - timedelta(seconds=get_otp_cooldown()):
            raise serializers.ValidationError(
                {"detail": "OTP already sent recently. Please wait before requesting again."}
            )

        EmailOTP.objects.filter(
            user=user,
            purpose=EmailOTP.PURPOSE_EMAIL_VERIFICATION,
            is_used=False,
        ).delete()

        otp = EmailOTP.create_for_user(
            user=user,
            purpose=EmailOTP.PURPOSE_EMAIL_VERIFICATION,
            ttl_minutes=get_otp_ttl(),
        )
        sent = send_otp_email(user.email, user.name, otp.code)
        if not sent:
            raise OTPDeliveryError()

        return validated_data


class SearchUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'name', 'profile_pic']
        read_only_fields = fields
