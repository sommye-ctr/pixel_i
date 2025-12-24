from rest_framework.exceptions import APIException


class OTPDeliveryError(APIException):
    status_code = 500
    default_detail = "Failed to send OTP. Please try again later."
    default_code = "otp_delivery_failed"
