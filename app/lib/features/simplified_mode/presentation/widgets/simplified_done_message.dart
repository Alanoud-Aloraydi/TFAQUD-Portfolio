import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'simplified_done_dose_taken.dart';
part 'simplified_done_dose_skipped.dart';
part 'simplified_done_glucose.dart';
part 'simplified_done_blood_pressure.dart';
part 'simplified_done_visit_attended.dart';

/// What «تم، شكرًا» says was saved, exactly.
sealed class SimplifiedDoneMessage {
  const SimplifiedDoneMessage();

  /// «سجّلنا أنك أخذت ميتفورمين، 6:04 مساءً».
  const factory SimplifiedDoneMessage.doseTaken(String name, DateTime at) =
      SimplifiedDoneDoseTaken;

  /// «سجّلنا إنك ما أخذت ميتفورمين».
  const factory SimplifiedDoneMessage.doseSkipped(String name) =
      SimplifiedDoneDoseSkipped;

  /// «سجّلنا قياس السكر: 112», and «طبيعي» under it.
  const factory SimplifiedDoneMessage.glucose(
    int value, {
    MeasurementLevel? level,
  }) = SimplifiedDoneGlucose;

  /// «سجّلنا الضغط: 127/80», and «طبيعي» under it.
  const factory SimplifiedDoneMessage.bloodPressure(
    int upper,
    int lower, {
    MeasurementLevel? level,
  }) = SimplifiedDoneBloodPressure;

  /// «سجّلنا أنك حضرت الموعد: متابعة».
  const factory SimplifiedDoneMessage.visitAttended(String title) =
      SimplifiedDoneVisitAttended;

  String text(BuildContext context);

  /// How the reading was judged, or null when there is nothing to judge: a
  /// dose is taken or not, never «طبيعي».
  MeasurementVerdict? get verdict => null;
}
