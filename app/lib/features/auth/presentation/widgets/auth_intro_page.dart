import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro_layout.dart';
import 'package:app/features/auth/presentation/widgets/intro_enter_animation.dart';
import 'package:flutter/material.dart';

/// A page: the picture, and under it the step, the title and one line. When
/// the page shows, the picture's cards rise into place one after another;
/// this plays once each time, and not at all with Reduce Motion. The
/// picture takes the room the words leave.
class AuthIntroPage extends StatefulWidget {
  const AuthIntroPage({
    super.key,
    required this.intro,
    required this.step,
    required this.active,
  });

  final AuthIntro intro;

  /// 1, 2 or 3.
  final int step;

  /// Whether this is the page on show.
  final bool active;

  @override
  State<AuthIntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<AuthIntroPage>
    with SingleTickerProviderStateMixin, IntroEnterAnimation {
  @override
  bool get introActive => widget.active;

  @override
  void didUpdateWidget(AuthIntroPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) playEnter();
  }

  @override
  Widget build(BuildContext context) {
    return AuthIntroLayout(
      intro: widget.intro,
      step: widget.step,
      enter: enter,
    );
  }
}
