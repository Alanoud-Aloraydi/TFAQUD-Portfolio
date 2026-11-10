/// The Saudi mobile numbers the app reads and shows: sign-in, invitations,
/// circle requests and emergency contacts. Sign-in is by SMS through a Saudi
/// provider, so these are the numbers accounts have (a product decision; a
/// number of another country needs a country-code picker first).
///
/// The national number is what the phone field holds: nine digits 0-9 that
/// start with 5, with no country code and no leading zero (`501234567`). The
/// international number is what the API takes (`+966501234567`).
abstract final class SaudiMobile {
  static const String countryCode = '+966';

  /// The length of a national number.
  static const int digits = 9;

  static final RegExp _national = RegExp(r'^5[0-9]{8}$');

  /// True for a whole national number, such as `501234567`.
  static bool isValid(String national) => _national.hasMatch(national);

  /// `501234567` becomes `+966501234567`.
  static String international(String national) => '$countryCode$national';

  /// `+966501234567` becomes `501234567`; a text without the country code is
  /// returned as it is.
  static String national(String international) =>
      international.startsWith(countryCode)
      ? international.substring(countryCode.length)
      : international;

  /// `501234567` becomes `50 123 4567`, also while it is being typed.
  static String group(String national) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < national.length; i++) {
      if (i == 2 || i == 5) out.write(' ');
      out.write(national[i]);
    }
    return out.toString();
  }

  /// `+966501234567` becomes `+966 50 123 4567`, in the digits 0-9; shown
  /// left to right.
  static String display(String international) =>
      '$countryCode ${group(national(international))}';
}
