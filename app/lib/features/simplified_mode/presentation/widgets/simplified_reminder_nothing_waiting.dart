import 'package:app/app/router/routers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The reminder's task is no longer waiting (someone in the family may
/// have recorded it, or it is of another circle), so there is nothing to
/// answer. It is read aloud as it opens, like the reminder it replaces.
class SimplifiedReminderNothingWaiting extends StatelessWidget {
  const SimplifiedReminderNothingWaiting({super.key});

  @override
  Widget build(BuildContext context) {
    final String title = context.tr('simplified_mode.nothing_waiting');
    final String text = context.tr('simplified_mode.nothing_waiting_text');
    final String back = context.tr('simplified_mode.back_home');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 24),
          MergeSemantics(
            child: Column(
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.display,
                    color: SimplifiedColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: SimplifiedStyle.text(
                    SimplifiedStyle.body,
                    color: SimplifiedColors.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 32),
          SimplifiedButton(
            label: back,
            tone: SimplifiedButtonTone.secondary,
            onPressed: () => context.go(Routes.simplifiedMode),
          ),
        ],
      ),
    );
  }
}

/// What a full-screen reminder shows: its words, its picture, and its
/// answers.
class SimplifiedReminderContent {
  const SimplifiedReminderContent({
    required this.lead,
    required this.name,
    required this.line,
    required this.hero,
    required this.yesLabel,
    required this.onYes,
    this.chips = const <String>[],
    this.people,
    this.onLater,
  });

  final String lead;
  final String name;
  final String line;
  final List<String> chips;

  /// The picture, filling a frame of the height given: the screen decides
  /// how tall it can be.
  final Widget Function(double height) hero;

  /// Who comes along to a visit, each one's photo before their name.
  final Widget? people;
  final String yesLabel;
  final VoidCallback? onYes;

  /// Null for an appointment, which has nothing to put off.
  final VoidCallback? onLater;
}
