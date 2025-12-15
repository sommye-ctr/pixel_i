from urllib.parse import parse_qs

from channels.middleware import BaseMiddleware
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from jwt import decode
from rest_framework_simplejwt.tokens import UntypedToken

from pixel_i import settings

User = get_user_model()


class JWTAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = scope["query_string"].decode()
        params = parse_qs(query_string)
        token = params.get("token")

        if not token:
            scope["user"] = AnonymousUser()
            return await super().__call__(scope, receive, send)

        try:
            token = token[0]
            UntypedToken(token)

            decoded = decode(
                token,
                settings.SECRET_KEY,
                algorithms=["HS256"],
            )
            scope["user"] = User.objects.get(id=decoded["user_id"])

        except Exception:
            scope["user"] = AnonymousUser()

        return await super().__call__(scope, receive, send)
