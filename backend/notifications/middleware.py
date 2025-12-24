from urllib.parse import parse_qs

from asgiref.sync import sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth import get_user_model


class JWTAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = scope["query_string"].decode()
        params = parse_qs(query_string)
        token = params.get("token")

        from django.contrib.auth.models import AnonymousUser
        if not token:
            scope["user"] = AnonymousUser()
            return await super().__call__(scope, receive, send)

        from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
        from rest_framework_simplejwt.tokens import AccessToken
        try:
            acc = AccessToken(token=token[0])
            scope["user"] = await sync_to_async(get_user_model().objects.get)(id=acc['user_id'])
            print(f"WS USER ID GOT {acc['user_id']}")

        except (InvalidToken, TokenError):
            scope["user"] = AnonymousUser()

        return await super().__call__(scope, receive, send)
