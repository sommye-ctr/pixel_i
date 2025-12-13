import os

from dotenv import load_dotenv

load_dotenv()


def get_otp_ttl():
    return int(os.getenv("EMAIL_OTP_TTL"))


def get_otp_max_attempts():
    return int(os.getenv("EMAIL_OTP_MAX_ATTEMPTS"))


def get_otp_cooldown():
    return int(os.getenv("EMAIL_OTP_COOLDOWN"))
