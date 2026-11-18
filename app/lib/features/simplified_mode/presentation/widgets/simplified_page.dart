import 'package:app/features/simplified_mode/presentation/widgets/simplified_page_back.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page_footer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page_title.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// A sub-screen: «رجوع» on top, a big title, the body scrolling, and an
/// optional action pinned at the bottom.
///
/// The title is a heading for VoiceOver and TalkBack, so the reader can
/// jump straight to it.
class SimplifiedPage extends StatelessWidget {
  const SimplifiedPage({
    super.key,
    required this.title,
    required this.children,
    this.backKey = 'simplified_mode.back',
    this.titleTrailing,
    this.footer,
  });

  final String title;
  final List<Widget> children;

  /// «رجوع», or «إغلاق» for a screen that saves something.
  final String backKey;
  final Widget? titleTrailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return _scaffold(context);
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: SimplifiedColors.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SimplifiedPageBack(backKey: backKey),
            SimplifiedPageTitle(title: title, trailing: titleTrailing),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  SimplifiedStyle.page,
                  SimplifiedStyle.pad,
                  SimplifiedStyle.page,
                  28,
                ),
                children: <Widget>[
                  for (final Widget child in children)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: SimplifiedStyle.gap,
                      ),
                      child: child,
                    ),
                ],
              ),
            ),
            if (footer case final Widget action)
              SimplifiedPageFooter(child: action),
          ],
        ),
      ),
    );
  }
}
