/// The words that name a circle after the person it cares for: "أمي", "أبي",
/// "جدتي"... A circle for another person is named with the chosen word followed
/// by the first name of the patient, for example "أمي نورة". [other] lets the
/// user type a word of their own.
enum CircleLabel {
  mother,
  father,
  grandmother,
  grandfather,
  wife,
  husband,
  brother,
  sister,
  other,
}

/// How the name of a circle is made from a label and the patient's first name.
abstract class CircleNames {
  CircleNames._();

  /// The longest typed label. The API accepts 30 for a circle request.
  static const int maxLabelLength = 30;

  /// The longest circle name the API accepts.
  static const int maxLength = 60;

  /// "أمي" and "نورة" become "أمي نورة". A name longer than [maxLength] is cut
  /// at the end, so a long typed label with a long first name is still accepted.
  static String compose(String label, String firstName) {
    final String name = '${label.trim()} ${firstName.trim()}'.trim();
    if (name.length <= maxLength) return name;
    return name.substring(0, maxLength).trimRight();
  }
}
