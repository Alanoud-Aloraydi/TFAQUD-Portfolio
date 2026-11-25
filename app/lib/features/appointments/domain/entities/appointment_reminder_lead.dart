/// How long before a visit its own reminder comes.
///
/// Every appointment is reminded twice: once the day before, which is
/// fixed, and once shortly before its time, which is this. It used to be
/// two hours for every visit alike — too early for the clinic in the same
/// building, too late for the one across the city — so each visit now
/// carries the lead chosen when it was booked, on the ruler of «ذكّرني
/// لاحقًا»: 5 minutes a mark, up to 6 hours.
library;

/// The shortest and the longest lead, in minutes; the server takes the
/// same (`backend/app/appointments/inputs.py`).
const int minAppointmentLead = 5;
const int maxAppointmentLead = 360;

/// An hour before, which suits most visits and is what a visit saved
/// before this choice existed keeps.
const int defaultAppointmentLead = 60;
