/// How long before a visit its own reminder comes.
///
/// Every appointment is reminded twice: once the day before, which is
/// fixed, and once shortly before its time, which is this. It used to be
/// two hours for every visit alike — too early for the clinic in the same
/// building, too late for the one across the city — so each visit now
/// carries the lead chosen when it was booked.
library;

/// What the form offers, soonest first: half an hour up to three hours.
const List<int> appointmentLeadChoices = <int>[30, 60, 120, 180];

/// An hour before, which suits most visits and is what a visit saved
/// before this choice existed keeps.
const int defaultAppointmentLead = 60;
