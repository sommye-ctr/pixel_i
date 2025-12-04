from django.db.models import Q
from rest_framework import generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView

from accounts.models import CustomUser
from accounts.serializers import SignupSerializer, SearchUserSerializer


class SignupView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    permission_classes = [AllowAny]
    serializer_class = SignupSerializer

    def perform_create(self, serializer):
        user = serializer.save()
        # TODO implement otp based verification
        # send email with otp to user
        # return the signup user serializer object from here


class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]


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
