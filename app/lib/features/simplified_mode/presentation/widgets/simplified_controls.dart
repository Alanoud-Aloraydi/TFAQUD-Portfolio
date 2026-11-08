import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/services/simplified_voice.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The look of a [SimplifiedButton].
enum SimplifiedButtonTone { primary, secondary, danger, dark, quiet }

/// The mode's 72-high capsule button, full width.
class SimplifiedButton extends StatelessWidget {
  const SimplifiedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SimplifiedButtonTone.primary,
    this.icon,
  });

  final String label;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;
  final SimplifiedButtonTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color text, BorderSide side) = switch (tone) {
      SimplifiedButtonTone.primary => (
        SimplifiedStyle.accent,
        SimplifiedStyle.ink,
        BorderSide.none,
      ),
      SimplifiedButtonTone.secondary => (
        SimplifiedStyle.surface,
        SimplifiedStyle.ink,
        const BorderSide(color: SimplifiedStyle.control, width: 2),
      ),
      SimplifiedButtonTone.danger => (
        SimplifiedStyle.danger,
        SimplifiedStyle.surface,
        BorderSide.none,
      ),
      SimplifiedButtonTone.dark => (
        SimplifiedStyle.ink,
        SimplifiedStyle.surface,
        BorderSide.none,
      ),
      SimplifiedButtonTone.quiet => (
        SimplifiedStyle.chip,
        SimplifiedStyle.ink,
        BorderSide.none,
      ),
    };
    return SizedBox(
      width: double.infinity,
      height: SimplifiedStyle.action,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: text,
          disabledBackgroundColor: SimplifiedStyle.disabled,
          shape: StadiumBorder(side: side),
          padding: const EdgeInsets.symmetric(horizontal: SimplifiedStyle.pad),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 28),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: SimplifiedStyle.head(SimplifiedStyle.title, color: text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «استماع»: reads [segments] aloud, in order; «إيقاف» while it reads.
/// Hidden when the person turned reading off in «حسابي».
class ListenButton extends StatelessWidget {
  const ListenButton({super.key, required this.segments, this.onDark = false});

  final List<String> segments;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bool enabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.voiceEnabled,
    );
    if (!enabled) return const SizedBox.shrink();
    final SimplifiedVoice voice = GetIt.I<SimplifiedVoice>();
    final Color foreground = onDark
        ? SimplifiedStyle.surface
        : SimplifiedStyle.ink;
    return ValueListenableBuilder<bool>(
      valueListenable: voice.speaking,
      builder: (context, speaking, _) => SizedBox(
        height: SimplifiedStyle.touch,
        child: OutlinedButton.icon(
          onPressed: () => speaking ? voice.stop() : voice.speak(segments),
          icon: Icon(
            speaking ? CupertinoIcons.stop_fill : CupertinoIcons.speaker_2_fill,
            size: 24,
          ),
          label: Text(
            context.tr(
              speaking ? 'simplified_mode.stop' : 'simplified_mode.listen',
            ),
            style: SimplifiedStyle.head(
              SimplifiedStyle.caption,
              color: foreground,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: speaking
                ? SimplifiedStyle.accentTint.withValues(alpha: onDark ? .4 : 1)
                : SimplifiedStyle.clear,
            side: BorderSide(
              color: onDark
                  ? SimplifiedStyle.onDarkMuted
                  : SimplifiedStyle.control,
              width: 1.5,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: SimplifiedStyle.pad,
            ),
          ),
        ),
      ),
    );
  }
}

/// A sub-screen: «رجوع» and «استماع» on top, a big title, the body
/// scrolling, and an optional action pinned at the bottom.
class SimplifiedPage extends StatelessWidget {
  const SimplifiedPage({
    super.key,
    required this.title,
    required this.children,
    required this.listen,
    this.backKey = 'simplified_mode.back',
    this.titleTrailing,
    this.footer,
  });

  final String title;
  final List<Widget> children;

  /// What «استماع» reads, after the title.
  final List<String> listen;

  /// «رجوع», or «إغلاق» for a screen that saves something.
  final String backKey;
  final Widget? titleTrailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimplifiedStyle.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
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
                    icon: const Icon(AppIcons.back, size: 24),
                    label: Text(
                      context.tr(backKey),
                      style: SimplifiedStyle.label(SimplifiedStyle.body),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SimplifiedStyle.ink,
                      minimumSize: const Size(0, SimplifiedStyle.touch),
                    ),
                  ),
                  ListenButton(segments: <String>[title, ...listen]),
                ],
              ),
            ),
            Padding(
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
                    Text(
                      title,
                      style: SimplifiedStyle.head(SimplifiedStyle.display),
                    ),
                    ?titleTrailing,
                  ],
                ),
              ),
            ),
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
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SimplifiedStyle.page,
                  12,
                  SimplifiedStyle.page,
                  24,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// A white rounded card with a light edge.
class SimplifiedCard extends StatelessWidget {
  const SimplifiedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SimplifiedStyle.pad),
    this.color = SimplifiedStyle.surface,
    this.side = const BorderSide(color: SimplifiedStyle.line),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BorderSide side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
      side: side,
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// A small grey label («مع الأكل»), or a tappable choice when [onTap] is
/// set.
class SimplifiedChip extends StatelessWidget {
  const SimplifiedChip(
    this.text, {
    super.key,
    this.selected = false,
    this.onDark = false,
    this.onTap,
  });

  final String text;
  final bool selected;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool choice = onTap != null;
    final Color fill = onDark
        ? SimplifiedStyle.surface.withValues(alpha: .14)
        : selected
        ? SimplifiedStyle.accentTint
        : choice
        ? SimplifiedStyle.clear
        : SimplifiedStyle.chip;
    final Widget body = Container(
      height: choice ? 52 : null,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: choice ? 0 : 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(26),
        border: choice
            ? Border.all(color: SimplifiedStyle.control, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            text,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: onDark ? SimplifiedStyle.surface : SimplifiedStyle.ink,
            ),
          ),
          if (selected) ...<Widget>[
            const SizedBox(width: 6),
            const Icon(AppIcons.check, size: 18),
          ],
        ],
      ),
    );
    if (!choice) return body;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: body,
      ),
    );
  }
}

/// Two or three big choices in one capsule («ضغط الدم | سكر الدم»).
class SimplifiedSegmented<T> extends StatelessWidget {
  const SimplifiedSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SimplifiedStyle.surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: SimplifiedStyle.control, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<T, String> entry in segments.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == selected,
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    height: SimplifiedStyle.touch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == selected
                          ? SimplifiedStyle.surface
                          : SimplifiedStyle.clear,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      entry.value,
                      style: entry.key == selected
                          ? SimplifiedStyle.head(SimplifiedStyle.body)
                          : SimplifiedStyle.text(
                              SimplifiedStyle.body,
                              color: SimplifiedStyle.ink,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
