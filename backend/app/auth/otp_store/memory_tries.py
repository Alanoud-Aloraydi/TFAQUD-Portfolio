"""The in-memory store's wrong tries and accepted codes."""

from dataclasses import replace
from datetime import datetime


class MemoryTries:
    """Counts the tries of a request and marks it verified."""

    def claim_try(self, request_id: str, max_tries: int) -> bool:
        """Count one try on an open request with tries left; False otherwise.
        """
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is None
                or request.status != "pending"
                or request.wrong_tries >= max_tries
            ):
                return False
            self._requests[request_id] = replace(
                request, wrong_tries=request.wrong_tries + 1
            )
            return True

    def release_try(self, request_id: str) -> None:
        """Take back a try the provider could not decide."""
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is not None
                and request.status == "pending"
                and request.wrong_tries > 0
            ):
                self._requests[request_id] = replace(
                    request, wrong_tries=request.wrong_tries - 1
                )

    def mark_verified(self, request_id: str, at: datetime) -> bool:
        """Close an open request as accepted; False when it was already closed
        or unknown.
        """
        with self._lock:
            request = self._requests.get(request_id)
            if request is None or request.status != "pending":
                return False
            self._requests[request_id] = replace(
                request, status="verified", verified_at=at
            )
            return True
