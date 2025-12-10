from django.urls import path

from accounts.views import SignupView, LoginView, SearchUserView, EmailVerifyView, ResendEmailOTPView

urlpatterns = [
    path("signup/", SignupView.as_view()),
    path("login/", LoginView.as_view()),
    path("verify-email/", EmailVerifyView.as_view()),
    path("resend-email-otp/", ResendEmailOTPView.as_view()),
    path("search/", SearchUserView.as_view()),
]
