import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Placeholders for one part of a page that sits inside a scrolling page,
/// such as a medicine's dose history: the shimmer over a plain column, with
/// no scrolling of its own.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
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
