"""A glucose range: its normal band and the top of «elevated»."""

from dataclasses import dataclass


@dataclass(frozen=True)
class GlucoseRange:
    """mg/dL: the normal band and the top of «elevated»."""

    normal_low: int
    normal_high: int
    elevated_high: int

    def level(self, value: int) -> str:
        """Which of the four levels `value` is in."""
        if value < self.normal_low:
            return "low"
        if value <= self.normal_high:
            return "normal"
        if value <= self.elevated_high:
            return "elevated"
        return "high"

    def bands(self) -> list[dict]:
        """The four levels in order, each with its first and last value
        (None where it has no end)."""
        return [
            _glucose_band("low", None, self.normal_low - 1),
            _glucose_band("normal", self.normal_low, self.normal_high),
            _glucose_band(
                "elevated", self.normal_high + 1, self.elevated_high
            ),
            _glucose_band("high", self.elevated_high + 1, None),
        ]


def _glucose_band(level: str, low: int | None, high: int | None) -> dict:
    return {"level": level, "glucose_low": low, "glucose_high": high}
