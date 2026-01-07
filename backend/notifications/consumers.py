import json

from channels.generic.websocket import AsyncWebsocketConsumer


def user_group(user_id):
    return f"user_{str(user_id).replace('-', '')}"


class NotificationConsumer(AsyncWebsocketConsumer):
    user = None
    group = None

    async def connect(self):
        self.user = self.scope["user"]
        if not self.user.is_authenticated:
            await self.close()
            return

        self.group = f"user_{user_group(self.user.pk)}"

        await self.channel_layer.group_add(
            self.group,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        if self.group:
            await self.channel_layer.group_discard(
                self.group,
                self.channel_name
            )

    async def send_notification(self, event):
        await self.send(text_data=json.dumps(event["data"]))
