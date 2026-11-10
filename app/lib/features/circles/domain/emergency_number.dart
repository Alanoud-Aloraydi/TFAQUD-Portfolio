/// The ambulance number the emergency card calls. It is Saudi Arabia's
/// (997): the app does not store the patient's country, and a per-country
/// number is a product decision left open (see the notes' decisions). This
/// is the only place the number is written.
abstract final class EmergencyNumber {
  static const String ambulance = '997';
}
