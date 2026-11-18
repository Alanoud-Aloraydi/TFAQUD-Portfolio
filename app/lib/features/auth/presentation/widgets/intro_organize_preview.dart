import 'package:app/features/auth/presentation/widgets/intro_next_dose_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_reading_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:app/features/auth/presentation/widgets/intro_visit_card.dart';
import 'package:flutter/material.dart';

/// Page 1: the dark «الجرعة القادمة» card, and under it a reading and a
/// visit, each a little turned.
class IntroOrganizePreview extends StatelessWidget {
  const IntroOrganizePreview({super.key, required this.enter});

  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 0,
            child: const IntroNextDoseCard(),
          ),
        ),
        Positioned(
          top: 214,
          left: -6,
          right: 18,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: const IntroReadingCard(),
          ),
        ),
        Positioned(
          top: 300,
          left: 18,
          right: -6,
          child: IntroRise(
            enter: enter,
            order: 2,
            child: const IntroVisitCard(),
          ),
        ),
      ],
    );
  }
}
