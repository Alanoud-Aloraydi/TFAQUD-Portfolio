import 'package:app/features/measurements/domain/measurement.dart';

/// «ظروف القياس»: what was going on at a reading, one or more of them —
/// after a meal and after exercise at once, say.
///
/// An older server keeps one `glucose_context` and one `condition` instead;
/// these helpers read and write that shape too.
abstract final class MeasurementConditions {
  /// Where the stomach is: one of these at a time.
  static const List<String> mealStates = <String>[
    'fasting',
    'before_meal',
    'after_meal',
    'bedtime',
  ];

  /// What the form offers for [kind], in order. «قبل النوم» and «مرض» are
  /// still shown on a reading that has them.
  static List<String> offered(MeasurementKind kind) => switch (kind) {
    MeasurementKind.glucose => const <String>[
      'fasting',
      'before_meal',
      'after_meal',
      'exertion',
      'stress',
      'other',
    ],
    MeasurementKind.bp => const <String>['exertion', 'stress', 'other'],
  };

  /// [selected] with [code] switched on or off; a meal state replaces the
  /// one already chosen.
  static List<String> toggle(List<String> selected, String code) {
    if (selected.contains(code)) {
      return <String>[
        for (final String item in selected)
          if (item != code) item,
      ];
    }
    final bool meal = mealStates.contains(code);
    return <String>[
      for (final String item in selected)
        if (!(meal && mealStates.contains(item))) item,
      code,
    ];
  }

  /// The conditions in [json], or an older server's one context and one
  /// condition.
  static List<String> fromJson(Map<String, dynamic> json) {
    final List<dynamic>? listed = json['conditions'] as List<dynamic>?;
    if (listed != null) return listed.cast<String>();
    return fromLegacy(
      json['glucose_context'] as String?,
      json['condition'] as String?,
    );
  }

  /// Conditions from an older server's fields, once each.
  static List<String> fromLegacy(String? context, [String? condition]) =>
      <String>{?context, ?condition}.toList();

  /// The one `glucose_context` an older server keeps.
  static String? legacyContext(MeasurementKind kind, List<String> codes) {
    if (kind != MeasurementKind.glucose) return null;
    for (final String code in codes) {
      if (mealStates.contains(code)) return code;
    }
    return codes.contains('other') ? 'other' : null;
  }

  /// The one `condition` an older server keeps.
  static String? legacyCondition(MeasurementKind kind, List<String> codes) {
    for (final String code in codes) {
      if (const <String>['exertion', 'stress', 'illness'].contains(code) ||
          (kind == MeasurementKind.bp && code == 'after_meal')) {
        return code;
      }
    }
    return null;
  }

  /// Whether the older fields hold [codes] whole, so a reading time or a
  /// reading can be sent as before, to a server without lists too.
  static bool fitsLegacy(
    MeasurementKind kind,
    List<String> codes, {
    bool withCondition = false,
  }) {
    final List<String> legacy = fromLegacy(
      legacyContext(kind, codes),
      withCondition ? legacyCondition(kind, codes) : null,
    );
    return legacy.length == codes.length && legacy.every(codes.contains);
  }
}
