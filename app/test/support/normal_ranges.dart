import 'package:app/features/measurements/domain/normal_range.dart';

/// The general ranges, as the server sends them for a patient with neither
/// diabetes nor high blood pressure in the medical file.
NormalRanges generalRanges() => NormalRanges.fromJson(<String, dynamic>{
  'conditions': <String>[],
  'ranges': <Map<String, dynamic>>[
    _glucose('fasting', 70, 100, 125),
    _glucose('after_meal', 70, 140, 199),
    <String, dynamic>{
      'kind': 'blood_pressure',
      'profile': 'general',
      'state': null,
      'bands': <Map<String, dynamic>>[
        _pressure('low', null, 89, null, 59),
        _pressure('normal', 90, 120, 60, 80),
        _pressure('elevated', 121, 139, 81, 89),
        _pressure('high', 140, null, 90, null),
      ],
    },
  ],
});

Map<String, dynamic> _glucose(String state, int low, int high, int top) =>
    <String, dynamic>{
      'kind': 'glucose',
      'profile': 'general',
      'state': state,
      'bands': <Map<String, dynamic>>[
        <String, dynamic>{
          'level': 'low',
          'glucose_low': null,
          'glucose_high': low - 1,
        },
        <String, dynamic>{
          'level': 'normal',
          'glucose_low': low,
          'glucose_high': high,
        },
        <String, dynamic>{
          'level': 'elevated',
          'glucose_low': high + 1,
          'glucose_high': top,
        },
        <String, dynamic>{
          'level': 'high',
          'glucose_low': top + 1,
          'glucose_high': null,
        },
      ],
    };

Map<String, dynamic> _pressure(
  String level,
  int? systolicLow,
  int? systolicHigh,
  int? diastolicLow,
  int? diastolicHigh,
) => <String, dynamic>{
  'level': level,
  'systolic_low': systolicLow,
  'systolic_high': systolicHigh,
  'diastolic_low': diastolicLow,
  'diastolic_high': diastolicHigh,
};
