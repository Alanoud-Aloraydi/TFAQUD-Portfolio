import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A page's skeleton: its own placeholders ([children], in the page's
/// layout) with the shimmer over them. VoiceOver reads «جارٍ التحميل» once.
/// [padding] is the page's own padding; with [scrollInsets] the bars' heights
/// are added, as the page's list does.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.scrollInsets = true,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final bool scrollInsets;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: scrollInsets ? context.scrollPadding(padding) : padding,
            children: children,
          ),
        ),
      ),
    );
  }
}
