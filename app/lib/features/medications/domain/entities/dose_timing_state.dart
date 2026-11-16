/// Where an unrecorded dose stands against its time: not yet, due (its
/// first 15 minutes), late (until `DoseOccurrence.missedAfterMinutes`) or
/// missed. The server sends it; `medicationTimingState` recomputes it as
/// the minutes pass on screen.
enum DoseTimingState { upcoming, due, late, missed }
