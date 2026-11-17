import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:flutter/material.dart';

/// A main page that reads its data again when pulled down from its top,
/// the spinner showing until the data is back. A short page can be pulled
/// too: its scroll always follows the finger. Without a [RefreshScope]
/// above it, the page is left as it is.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Future<void> Function()? refresh = RefreshScope.maybeOf(context);
    if (refresh == null) return child;
    final ScrollBehavior behavior = ScrollConfiguration.of(context);
    return RefreshIndicator.adaptive(
      onRefresh: refresh,
      // Under the shell's glass top bar, not behind it.
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: behavior.getScrollPhysics(context),
          ),
        ),
        child: child,
      ),
    );
  }
}
