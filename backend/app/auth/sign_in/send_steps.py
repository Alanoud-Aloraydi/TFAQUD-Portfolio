"""The provider's part of a send, and the request a code is checked
against."""

from app import metrics
from app.errors import NotFound, ServiceUnavailable, ValidationFailed
from app.sms.base import SmsDeliveryError


class SignInSendSteps:
    """Calls the SMS provider and reads the request to verify."""

    def _send_code(self, phone: str, send_id: str) -> None:
        """Release quota only when the provider confirms rejection."""
        try:
            self._sms.send_code(phone)
        except SmsDeliveryError as error:
            metrics.increment("sign_in.code_not_sent")
            if error.delivery_rejected:
                self._otp.release_send(send_id)
            raise ServiceUnavailable(
                "The code could not be sent. Try again.",
                code="sms_unavailable",
            ) from None
        metrics.increment("sign_in.code_sent")
        sent_at = self._clock.now()
        self._otp.mark_sent(send_id, sent_at, sent_at + self._valid_for)

    def _verification_request(self, verification_id):
        """Reject closed or expired challenges before calling the provider."""
        # Unknown or replaced: 404; accepted already: «already used»; past its
        # time: «expired».
        request = self._otp.get_request(verification_id)
        if request is None:
            raise NotFound(
                "There is no verification request with this id. Start again.",
                code="verification_not_found",
            )
        if request.verified_at is not None:
            raise ValidationFailed(
                "This request is already finished. Start again.",
                code="code_already_used",
            )
        if request.status != "pending":
            raise NotFound(code="verification_not_found")
        if (
            request.expires_at is None
            or self._clock.now() > request.expires_at
        ):
            raise ValidationFailed(
                "The code has expired. Ask for a new one.", code="code_expired"
            )
        return request
