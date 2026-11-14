import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/features/auth/presentation/widgets/auth_words.dart';
import 'package:app/features/auth/presentation/widgets/intro_previews.dart';
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
    with SingleTickerProviderStateMixin {
  /// The most of the page the words take. With very large text they stop
  /// here and scroll, so the picture keeps the rest.
  static const double _wordsShare = 0.6;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.introEnter,
  );

  bool _reduceMotion = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _enter.value = 1;
    } else if (!_started && widget.active) {
      _play();
    }
    _started = true;
  }

  @override
  void didUpdateWidget(AuthIntroPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  void _play() {
    if (_reduceMotion) {
      _enter.value = 1;
    } else {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: IntroPreview(step: widget.step, enter: _enter),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * _wordsShare),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AuthWords(intro: widget.intro, step: widget.step),
            ),
          ),
        ],
      ),
    );
  }
}
