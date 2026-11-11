import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The look of a [SimplifiedButton].
enum SimplifiedButtonTone { primary, secondary, danger, dark, quiet }

/// The mode's capsule button, full width and at least 72 high.
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
    // At least [SimplifiedStyle.action] high, and taller when a large text
    // size wraps the label, so it is never cut off.
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(SimplifiedStyle.action),
          backgroundColor: fill,
          foregroundColor: text,
          disabledBackgroundColor: SimplifiedStyle.disabled,
          shape: StadiumBorder(side: side),
          padding: const EdgeInsets.symmetric(
            horizontal: SimplifiedStyle.pad,
            vertical: 12,
          ),
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

/// What a screen reads aloud, part by part in the order it shows them, for
/// its «استماع» and for the speaker of each [ListenTarget] under it.
class ListenScope extends InheritedWidget {
  const ListenScope({super.key, required this.parts, required super.child});

  final List<SpokenPart> parts;

  /// The parts of the screen [context] is in; none outside a screen that
  /// reads aloud.
  static List<SpokenPart> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ListenScope>()?.parts ??
      const <SpokenPart>[];

  @override
  bool updateShouldNotify(ListenScope oldWidget) =>
      !listEquals(oldWidget.parts, parts);
}

/// Reads [parts] aloud at the pace chosen in «حسابي», each as it is said
/// rather than written ([toSpeech]). On a phone without an Arabic voice it
/// says where to add one, unless [quietWithoutVoice]: a reading nobody
/// asked for then stays silent rather than show a message each time.
Future<void> readAloud(
  BuildContext context,
  List<SpokenPart> parts, {
  bool quietWithoutVoice = false,
}) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String missing = context.tr('simplified_mode.no_arabic_voice');
  final SpeechWords words = SpeechWords.of(context);
  final double rate = context
      .read<SimplifiedSettingsCubit>()
      .state
      .speechRate
      .rate;
  final bool spoken = await GetIt.I<SimplifiedVoice>().speak(<SpokenPart>[
    for (final SpokenPart part in parts)
      (id: part.id, text: toSpeech(part.text, words)),
  ], rate: rate);
  if (!spoken && !quietWithoutVoice) {
    if (messenger != null) {
      AppToast.showText(messenger, missing, kind: ToastKind.error);
    }
  }
}

/// «استماع»: reads the whole screen (its [ListenScope]) aloud, in the order
/// it shows; «إيقاف» while it reads. The part being read is marked by its
/// [ListenTarget]. Hidden when the person turned reading off in «حسابي».
class ListenButton extends StatelessWidget {
  const ListenButton({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bool enabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.voiceEnabled,
    );
    if (!enabled) return const SizedBox.shrink();
    final List<SpokenPart> parts = ListenScope.of(context);
    final SimplifiedVoice voice = GetIt.I<SimplifiedVoice>();
    final Color foreground = onDark
        ? SimplifiedStyle.surface
        : SimplifiedStyle.ink;
    return ValueListenableBuilder<bool>(
      valueListenable: voice.speaking,
      builder: (context, speaking, _) => OutlinedButton.icon(
        onPressed: () => speaking ? voice.stop() : readAloud(context, parts),
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
          // At least [SimplifiedStyle.touch] high; taller at a large text.
          minimumSize: const Size(0, SimplifiedStyle.touch),
          padding: const EdgeInsets.symmetric(
            horizontal: SimplifiedStyle.pad,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}

/// Reads its screen (its [ListenScope]) aloud once, as the screen opens,
/// while the person keeps «قراءة التذكير تلقائيًا» on; and stops whatever
/// is being read when the screen closes. For a full-screen reminder, which
/// the person may hear before they read it.
class ReadOnOpen extends StatefulWidget {
  const ReadOnOpen({super.key, required this.child});

  final Widget child;

  @override
  State<ReadOnOpen> createState() => _ReadOnOpenState();
}

class _ReadOnOpenState extends State<ReadOnOpen> {
  final SimplifiedVoice _voice = GetIt.I<SimplifiedVoice>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  @override
  void dispose() {
    unawaited(_voice.stop());
    super.dispose();
  }

  Future<void> _read() async {
    // Opened from a notification, the app may still be reading the
    // settings: their defaults must not speak for someone who chose
    // silence.
    final SimplifiedSettingsState settings = await context
        .read<SimplifiedSettingsCubit>()
        .whenLoaded();
    if (!mounted || !settings.voiceEnabled || !settings.autoRead) return;
    final List<SpokenPart> parts =
        context.getInheritedWidgetOfExactType<ListenScope>()?.parts ??
        const <SpokenPart>[];
    await readAloud(context, parts, quietWithoutVoice: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Where a [ListenTarget] shows the speaker that reads it alone.
enum ListenSpeaker {
  /// No speaker: a title, a button or a control, whose words are short or
  /// are its own label; «استماع» still reads it with the screen.
  none,

  /// At the end of a row inside a card, beside it.
  beside,

  /// On the top corner of a card, half over its edge, so it covers none
  /// of the card's own content.
  corner,
}

/// A part of a screen that «استماع» reads as the [SpokenPart] with [id]: it
/// is outlined while it is read, and scrolled into view, so the person sees
/// what they hear. With a [speaker], a tap on it reads this part alone.
class ListenTarget extends StatefulWidget {
  const ListenTarget({
    super.key,
    required this.id,
    required this.child,
    this.radius = SimplifiedStyle.radius,
    this.speaker = ListenSpeaker.none,
  });

  final Object id;
  final Widget child;

  /// The corners of the outline, those of [child]'s own shape.
  final double radius;
  final ListenSpeaker speaker;

  @override
  State<ListenTarget> createState() => _ListenTargetState();
}

class _ListenTargetState extends State<ListenTarget> {
  final ValueListenable<Object?> _reading = GetIt.I<SimplifiedVoice>().reading;
  bool _read = false;

  @override
  void initState() {
    super.initState();
    _read = _reading.value == widget.id;
    _reading.addListener(_changed);
  }

  @override
  void dispose() {
    _reading.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final bool read = _reading.value == widget.id;
    if (read == _read) return;
    setState(() => _read = read);
    if (!read) return;
    unawaited(
      Scrollable.ensureVisible(
        context,
        alignment: .2,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.formScroll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget outlined = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _read ? SimplifiedStyle.accent : SimplifiedStyle.clear,
          width: 4,
        ),
      ),
      child: widget.child,
    );
    if (widget.speaker == ListenSpeaker.none) return outlined;
    final bool enabled = context.select<SimplifiedSettingsCubit, bool>(
      (cubit) => cubit.state.voiceEnabled,
    );
    SpokenPart? part;
    for (final SpokenPart each in ListenScope.of(context)) {
      if (each.id == widget.id) {
        part = each;
        break;
      }
    }
    if (!enabled || part == null) return outlined;
    final Widget speaker = _PartSpeaker(part: part, reading: _read);
    return switch (widget.speaker) {
      ListenSpeaker.none => outlined,
      ListenSpeaker.beside => Row(
        children: <Widget>[
          Expanded(child: outlined),
          const SizedBox(width: 8),
          speaker,
        ],
      ),
      // The card moves down by half the speaker, which then sits over its
      // top edge.
      ListenSpeaker.corner => Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: _PartSpeaker.size / 2),
            child: outlined,
          ),
          PositionedDirectional(
            top: 0,
            end: SimplifiedStyle.pad,
            child: speaker,
          ),
        ],
      ),
    };
  }
}

/// The round speaker of a [ListenTarget]: reads its [part] alone, and turns
/// into «إيقاف» while that part is being read.
class _PartSpeaker extends StatelessWidget {
  const _PartSpeaker({required this.part, required this.reading});

  /// The simplified mode's least tap size ([SimplifiedStyle.touch]).
  static const double size = SimplifiedStyle.touch;

  final SpokenPart part;
  final bool reading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        reading ? 'simplified_mode.stop' : 'simplified_mode.listen_part',
      ),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: IconButton(
          onPressed: () => reading
              ? GetIt.I<SimplifiedVoice>().stop()
              : readAloud(context, <SpokenPart>[part]),
          style: IconButton.styleFrom(
            backgroundColor: reading
                ? SimplifiedStyle.accentTint
                : SimplifiedStyle.surface,
            foregroundColor: SimplifiedStyle.ink,
            side: const BorderSide(color: SimplifiedStyle.control, width: 1.5),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            reading ? CupertinoIcons.stop_fill : CupertinoIcons.speaker_2_fill,
            size: 22,
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

  /// What «استماع» reads after the title, part by part in the order the
  /// screen shows them; each part's [ListenTarget] is in [children].
  final List<SpokenPart> listen;

  /// The [SpokenPart.id] of the title.
  static const Object titlePart = #title;

  /// «رجوع», or «إغلاق» for a screen that saves something.
  final String backKey;
  final Widget? titleTrailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListenScope(
      parts: <SpokenPart>[(id: titlePart, text: title), ...listen],
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
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
                  const ListenButton(),
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
                    ListenTarget(
                      id: titlePart,
                      radius: 8,
                      child: Text(
                        title,
                        style: SimplifiedStyle.head(SimplifiedStyle.display),
                      ),
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
    // A choice is at least [SimplifiedStyle.touch] high, and grows with a
    // large text.
    final Widget body = Container(
      constraints: choice
          ? const BoxConstraints(minHeight: SimplifiedStyle.touch)
          : null,
      alignment: choice ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                    constraints: const BoxConstraints(
                      minHeight: SimplifiedStyle.touch,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
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
