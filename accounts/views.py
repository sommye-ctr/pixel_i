from rest_framework import generics
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView

from accounts.models import CustomUser
from accounts.serializers import SignupSerializer


class SignupView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    permission_classes = [AllowAny]
    serializer_class = SignupSerializer

    def perform_create(self, serializer):
        user = serializer.save()
        #TODO implement otp based verification
        # send email with otp to user
        # return the signup user serializer object from here

class LoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
