import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

  String text(BuildContext context);

  /// How the reading was judged, in one word, or null when there is
  /// nothing to judge: a dose is taken or not, never «طبيعي».
  MeasurementVerdict? verdict(BuildContext context) => null;
}

/// A reading's level in the words and the icon every page uses for it.
class MeasurementVerdict {
  const MeasurementVerdict(this.label, this.level);

  final String label;
  final MeasurementLevel level;
}

class SimplifiedDoneDoseTaken extends SimplifiedDoneMessage {
  const SimplifiedDoneDoseTaken(this.name, this.at);

  final String name;
  final DateTime at;

  @override
  String text(BuildContext context) {
    return context.tr(
      'simplified_mode.done_dose',
      args: <String>[name, simplifiedClockAt(context, at)],
    );
  }
}

class SimplifiedDoneDoseSkipped extends SimplifiedDoneMessage {
  const SimplifiedDoneDoseSkipped(this.name);

  final String name;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_skipped', args: <String>[name]);
}

class SimplifiedDoneGlucose extends SimplifiedDoneMessage {
  const SimplifiedDoneGlucose(this.value, {this.level});

  final int value;
  final MeasurementLevel? level;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_glucose', args: <String>['$value']);

  @override
  MeasurementVerdict? verdict(BuildContext context) => level == null
      ? null
      : MeasurementVerdict(
          level!.label(context, MeasurementKind.glucose),
          level!,
        );
}

class SimplifiedDoneBloodPressure extends SimplifiedDoneMessage {
  const SimplifiedDoneBloodPressure(this.upper, this.lower, {this.level});

  final int upper;
  final int lower;
  final MeasurementLevel? level;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_bp', args: <String>['$upper', '$lower']);

  @override
  MeasurementVerdict? verdict(BuildContext context) => level == null
      ? null
      : MeasurementVerdict(level!.label(context, MeasurementKind.bp), level!);
}
