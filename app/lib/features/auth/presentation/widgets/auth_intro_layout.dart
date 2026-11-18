import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/features/auth/presentation/widgets/auth_words.dart';
import 'package:app/features/auth/presentation/widgets/intro_previews.dart';
import 'package:flutter/material.dart';

/// The picture over the words of an intro page. The picture takes the room
/// the words leave.
class AuthIntroLayout extends StatelessWidget {
  const AuthIntroLayout({
    super.key,
    required this.intro,
    required this.step,
    required this.enter,
  });

  final AuthIntro intro;

  /// 1, 2 or 3.
  final int step;

  final Animation<double> enter;

  /// The most of the page the words take. With very large text they stop
  /// here and scroll, so the picture keeps the rest.
  static const double _wordsShare = 0.6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: IntroPreview(step: step, enter: enter),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * _wordsShare),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AuthWords(intro: intro, step: step),
            ),
          ),
        ],
      ),
    );
  }
}
