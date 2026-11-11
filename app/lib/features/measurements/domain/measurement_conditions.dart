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
}
