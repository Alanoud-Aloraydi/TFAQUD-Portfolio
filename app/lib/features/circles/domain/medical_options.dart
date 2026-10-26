/// The choices of the health pages, written as the API codes them
/// (docs/api-contracts.md, "The medical file"). The order is the order of the
/// design. The text of each choice is in assets/translations/ar.json, group
/// "medical": `medical.condition.<code>`, `medical.medication.<code>` and
/// `medical.food.<code>`.
abstract class MedicalOptions {
  MedicalOptions._();

  /// The code of the choice that means "none of them".
  static const String none = 'none';

  /// The code of the choice that asks the user to type the item.
  static const String other = 'other';

  /// The longest text the API accepts for an "other" item.
  static const int otherMaxLength = 100;

  static const List<String> bloodTypes = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  /// Chronic conditions, without "none" and "other".
  static const List<String> conditions = <String>[
    'diabetes',
    'hypertension',
    'heart',
    'asthma',
    'kidney',
    'thyroid',
  ];

  /// Medicines a person can be allergic to, without "other".
  static const List<String> medications = <String>[
    'penicillin',
    'sulfa',
    'cephalosporins',
    'aspirin_nsaids',
    'contrast_media',
    'anesthesia',
  ];

  /// Foods a person can be allergic to, without "other".
  static const List<String> foods = <String>[
    'milk',
    'eggs',
    'fish',
    'shellfish',
    'tree_nuts',
    'peanuts',
    'wheat',
    'soy',
    'sesame',
  ];
}
