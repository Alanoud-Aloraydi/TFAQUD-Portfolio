import 'package:app/features/auth/presentation/widgets/intro_follow_people.dart';
import 'package:app/features/auth/presentation/widgets/intro_follow_pill.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:flutter/material.dart';

/// Page 3: the person switcher of the top bar, and the list it opens.
class IntroFollowPreview extends StatelessWidget {
  const IntroFollowPreview({super.key, required this.enter});

  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 0,
            child: const IntroFollowPill(),
          ),
        ),
        Positioned(
          top: 74,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: const IntroFollowPeople(),
          ),
        ),
      ],
    );
  }
}
