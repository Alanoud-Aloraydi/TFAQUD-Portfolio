import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:app/features/auth/presentation/widgets/intro_share_members.dart';
import 'package:app/features/auth/presentation/widgets/intro_share_note.dart';
import 'package:flutter/material.dart';

/// Page 2: the members of the circle, and a dark note over them.
class IntroSharePreview extends StatelessWidget {
  const IntroSharePreview({super.key, required this.enter});

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
            child: const IntroShareMembers(),
          ),
        ),
        Positioned(
          top: 300,
          left: 8,
          right: 8,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: const IntroShareNote(),
          ),
        ),
      ],
    );
  }
}
