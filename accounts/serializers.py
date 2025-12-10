from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.generics import get_object_or_404

from accounts.models import CustomUser, EmailOTP
from utils.auth_utils import get_otp_max_attempts

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
        email = attrs["email"]
        otp = attrs["otp"]

        user = get_object_or_404(CustomUser, email=email)
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
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            raise serializers.ValidationError({"otp": "Invalid OTP."})

        self.context["user"] = user
        self.context["otp"] = otp
        return attrs

    def create(self, validated_data):
        user = self.context["user"]
        otp = self.context["otp"]

        otp.is_used = True
        otp.save(update_fields=["is_used"])

        user.is_active = True
        user.save(update_fields=["is_active"])

        return {"detail": "Email verified successfully."}


class SearchUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'name', 'profile_pic']
        read_only_fields = fields
