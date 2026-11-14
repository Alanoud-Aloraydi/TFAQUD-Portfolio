import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What «تم، شكرًا» says was saved, exactly.
sealed class SimplifiedDoneMessage {
  const SimplifiedDoneMessage();

  /// «سجّلنا أنك أخذت ميتفورمين · 6:04 مساءً».
  const factory SimplifiedDoneMessage.doseTaken(String name, DateTime at) =
      SimplifiedDoneDoseTaken;

  /// «سجّلنا قياس السكر: 112».
  const factory SimplifiedDoneMessage.glucose(int value) =
      SimplifiedDoneGlucose;

  /// «سجّلنا الضغط: 127/80».
  const factory SimplifiedDoneMessage.bloodPressure(int upper, int lower) =
      SimplifiedDoneBloodPressure;

  String text(BuildContext context);
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

class SimplifiedDoneGlucose extends SimplifiedDoneMessage {
  const SimplifiedDoneGlucose(this.value);

  final int value;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_glucose', args: <String>['$value']);
}

class SimplifiedDoneBloodPressure extends SimplifiedDoneMessage {
  const SimplifiedDoneBloodPressure(this.upper, this.lower);

  final int upper;
  final int lower;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_bp', args: <String>['$upper', '$lower']);
}
