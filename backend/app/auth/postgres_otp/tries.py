"""The PostgreSQL store's wrong tries and accepted codes."""

from app.models import OtpRequest as OtpRequestRow


class PostgresTries:
    """Counts the tries of a request and marks it verified."""

    def claim_try(self, request_id, max_tries):
        """Count one try on an open request with tries left, in one statement;
        False otherwise.
        """
        return self._update_request(
            request_id,
            OtpRequestRow.wrong_try_count < max_tries,
            wrong_try_count=OtpRequestRow.wrong_try_count + 1,
        )

    def release_try(self, request_id):
        """Take back a try the provider could not decide, never below zero."""
        self._update_request(
            request_id,
            OtpRequestRow.wrong_try_count > 0,
            wrong_try_count=OtpRequestRow.wrong_try_count - 1,
        )

    def mark_verified(self, request_id, at):
        """Close an open request as accepted; False when it was already closed
        or unknown.
        """
        return self._update_request(
            request_id,
            OtpRequestRow.verified_at.is_(None),
            status="verified",
            verified_at=at,
        )
