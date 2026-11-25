import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

/// The action pinned at the bottom of a sub-screen.
class SimplifiedPageFooter extends StatelessWidget {
  const SimplifiedPageFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        12,
        SimplifiedStyle.page,
        24,
      ),
      child: child,
    );
  }
}

/// The «رجوع» button on top of a sub-screen.
class SimplifiedPageBack extends StatelessWidget {
  const SimplifiedPageBack({super.key, required this.backKey});

  /// «رجوع», or «إغلاق» for a screen that saves something.
  final String backKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        8,
        SimplifiedStyle.page,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            // In right-to-left, «back» points to the right.
            icon: const Icon(ArrowIcons.back, size: 24),
            label: Text(
              context.tr(backKey),
              style: SimplifiedStyle.label(SimplifiedStyle.body),
            ),
            style: TextButton.styleFrom(
              foregroundColor: SimplifiedColors.ink,
              minimumSize: const Size(0, SimplifiedStyle.touch),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sub-screen's big title, a heading for VoiceOver and TalkBack, with an
/// optional widget beside it.
class SimplifiedPageTitle extends StatelessWidget {
  const SimplifiedPageTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        12,
        SimplifiedStyle.page,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: SimplifiedStyle.head(SimplifiedStyle.display),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
