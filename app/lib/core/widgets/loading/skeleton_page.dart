import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/scroll_insets.dart';
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
      label: spoken(context.tr('common.loading')),
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

/// Placeholders for one part of a page that sits inside a scrolling page,
/// such as a medicine's dose history: the shimmer over a plain column, with
/// no scrolling of its own.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spoken(context.tr('common.loading')),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The white card the real content sits on, holding placeholders.
class SkeletonSurface extends StatelessWidget {
  const SkeletonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppSurfaces.card(),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A round placeholder, such as an avatar.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, radius: size / 2);
  }
}
