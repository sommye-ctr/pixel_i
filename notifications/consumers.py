import json

from channels.generic.websocket import AsyncWebsocketConsumer


class NotificationConsumer(AsyncWebsocketConsumer):
    user = None
    group = None

    async def connect(self):
        self.user = self.scope["user"]

        if not self.user.is_authenticated:
            await self.close()
            return

        self.group = f"user_{self.user.id}"

        await self.channel_layer.group_add(
            self.group,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.group,
            self.channel_name
        )

    async def send_notification(self, event):
        await self.send(text_data=json.dumps(event["data"]))
