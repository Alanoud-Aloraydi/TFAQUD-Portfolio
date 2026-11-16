"""A blood pressure range: the bottom and top of normal, and the top of
«elevated»."""

from dataclasses import dataclass


@dataclass(frozen=True)
class PressureRange:
    """mmHg: the bottom and top of normal, and the top of «elevated»."""

    systolic_low: int
    diastolic_low: int
    systolic_high: int
    diastolic_high: int
    systolic_elevated: int
    diastolic_elevated: int

    def level(self, systolic: int, diastolic: int) -> str:
        """Which of the four levels a reading is in; the worse number
        decides, and high wins over low."""
        if (
            systolic > self.systolic_elevated
            or diastolic > self.diastolic_elevated
        ):
            return "high"
        if systolic < self.systolic_low or diastolic < self.diastolic_low:
            return "low"
        if systolic > self.systolic_high or diastolic > self.diastolic_high:
            return "elevated"
        return "normal"

    def bands(self) -> list[dict]:
        """The four levels in order, as in `GlucoseRange.bands`."""
        return [
            _pressure_band(
                "low", (None, self.systolic_low - 1),
                (None, self.diastolic_low - 1),
            ),
            _pressure_band(
                "normal", (self.systolic_low, self.systolic_high),
                (self.diastolic_low, self.diastolic_high),
            ),
            _pressure_band(
                "elevated",
                (self.systolic_high + 1, self.systolic_elevated),
                (self.diastolic_high + 1, self.diastolic_elevated),
            ),
            _pressure_band(
                "high", (self.systolic_elevated + 1, None),
                (self.diastolic_elevated + 1, None),
            ),
        ]


def _pressure_band(level: str, systolic: tuple, diastolic: tuple) -> dict:
    return {
        "level": level,
        "systolic_low": systolic[0],
        "systolic_high": systolic[1],
        "diastolic_low": diastolic[0],
        "diastolic_high": diastolic[1],
    }
