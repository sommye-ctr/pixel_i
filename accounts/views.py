from django.db.models import Q
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from accounts.errors import OTPDeliveryError
from accounts.models import CustomUser, EmailOTP
from accounts.serializers import SignupSerializer, SearchUserSerializer, EmailVerifySerializer, ResendEmailOTPSerializer
from utils.auth_utils import get_otp_ttl, send_otp_email


class SignupView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    permission_classes = [AllowAny]
    serializer_class = SignupSerializer

    def perform_create(self, serializer):
        user = serializer.save()
        otp = EmailOTP.create_for_user(user, get_otp_ttl())
        otp.save()
        sent = send_otp_email(user.email, user.name, otp.code)
        if not sent:
            raise OTPDeliveryError()
        return user


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]


class EmailVerifyView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = EmailVerifySerializer

    def post(self, request, *args, **kwargs):
        serializer = EmailVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        access = refresh.access_token

        return Response(
            {"access": access, "refresh": refresh.__str__(), "detail": "Email Verified successfully"},
            status=status.HTTP_200_OK,
        )


class ResendEmailOTPView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = ResendEmailOTPSerializer

    def post(self, request, *args, **kwargs):
        serializer = ResendEmailOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {"detail": "OTP resent to your email."},
            status=status.HTTP_200_OK,
        )


class SearchUserView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SearchUserSerializer

    def get_queryset(self):
        q = self.request.query_params.get('q', '').strip()
        limit = self.request.query_params.get('l', '').strip()

        if not q:
            return CustomUser.objects.none()
        try:
            limit = int(limit) if limit else 20
        except ValueError:
            limit = 20

        return CustomUser.objects.filter(
            Q(username__istartswith=q) |
            Q(name__istartswith=q)
        )[:limit]
