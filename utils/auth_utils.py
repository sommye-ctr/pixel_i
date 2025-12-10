import os

import requests
from dotenv import load_dotenv

load_dotenv()


def send_otp_email(email, name, otp):
    payload = {
        "templateId": 1,
        "params": {"OTP": str(otp)},
        "to": [
            {
                "email": email,
                "name": name
            }
        ],
        "sender": {
            "email": os.getenv("EMAIL_SENDER_MAIL"),
            "name": "Pixel-i",
        }
    }

    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "api-key": os.getenv("EMAIL_SENDER_API")
    }

    response = requests.post('https://api.brevo.com/v3/smtp/email', headers=headers, json=payload)
    if response.status_code == 201:
        return True
    return False
