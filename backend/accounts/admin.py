from django.contrib import admin
from accounts.models import CustomUser, Role, EmailOTP

admin.site.register(CustomUser)
admin.site.register(Role)
admin.site.register(EmailOTP)
