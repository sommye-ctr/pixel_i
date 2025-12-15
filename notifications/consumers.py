import json

from channels.generic.websocket import AsyncWebsocketConsumer


class NotificationConsumer(AsyncWebsocketConsumer):
    user = None

    async def connect(self):
        self.user = self.scope["user"]

        if not self.user.is_authenticated:
            await self.close()
            return

        await self.accept()

    async def disconnect(self, close_code):
        pass

    async def send_notification(self, event):
        await self.send(text_data=json.dumps(event["data"]))
