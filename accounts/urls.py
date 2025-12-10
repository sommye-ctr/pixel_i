from django.urls import path

from accounts.views import SignupView, LoginView, SearchUserView, EmailVerifyView

urlpatterns = [
    path("signup/", SignupView.as_view()),
    path("login/", LoginView.as_view()),
    path("verify-email/", EmailVerifyView.as_view()),
    path("search/", SearchUserView.as_view()),
]
