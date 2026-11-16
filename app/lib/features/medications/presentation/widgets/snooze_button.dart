import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/snooze_button_state.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «ذكّرني لاحقًا»: the dose's own reminder again, as late as the person
/// slides the ruler of [showSnoozeSheet] (5 minutes a mark, up to 12 hours,
/// and never past halfway to the medicine's next dose), with the same
/// words as its notification. Once put off, the button says when it comes
/// («بنذكّرك 2:36 م»), and opens the ruler again. Put off by someone else
/// in the circle, it says until when and who («مؤجّلة إلى 2:36 م، لين»).
class SnoozeButton extends StatefulWidget {
  const SnoozeButton({required this.occurrence, required this.circleId});

  final DoseOccurrence occurrence;
  final String circleId;

  @override
  State<SnoozeButton> createState() => SnoozeButtonState();
}
