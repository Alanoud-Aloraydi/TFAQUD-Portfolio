import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/intro_attention_picture.dart';
import 'package:app/features/auth/presentation/widgets/intro_circles_picture.dart';
import 'package:app/features/auth/presentation/widgets/intro_members_picture.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The welcome's pages, each a real part of the app with example data.
const List<Widget> introPages = <Widget>[
  IntroPage(picture: IntroCirclesPicture(), words: 'intro.p1'),
  IntroPage(picture: IntroMembersPicture(), words: 'intro.p2'),
  IntroPage(picture: IntroAttentionPicture(), words: 'intro.p3'),
];

/// A page: the picture in the room left, then the title and one line. With
/// large text the page scrolls instead of overflowing.
class IntroPage extends StatelessWidget {
  const IntroPage({super.key, required this.picture, required this.words});

  final Widget picture;

  /// The page's keys in ar.json: `$words.title` and `$words.body`.
  final String words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? body = text.bodyLarge?.copyWith(
      color: AppSemanticColors.textSupporting,
    );
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: <Widget>[
                // An example, not the app: it takes no taps.
                Expanded(
                  child: Center(child: IgnorePointer(child: picture)),
                ),
                Text(context.tr('$words.title'), style: text.displaySmall),
                Text(context.tr('$words.body'), style: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
