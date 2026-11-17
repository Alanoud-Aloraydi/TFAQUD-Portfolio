import 'package:app/core/widgets/loading/page_skeleton.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:flutter/material.dart';

/// A page that is loading. With no [size] it is the page's shimmering
/// skeleton (design system Skeleton), so every loading page shimmers instead
/// of spinning. With a [size] it is the app's turning logo ([TfaqudLoader]),
/// for a screen or a control that is busy, such as a dose being recorded.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final double? spinner = size;
    if (spinner == null) return const PageSkeleton();
    return Center(child: TfaqudLoader(size: spinner));
  }
}
