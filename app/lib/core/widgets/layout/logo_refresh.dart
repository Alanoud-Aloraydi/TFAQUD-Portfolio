import 'package:app/core/widgets/layout/pull_to_refresh.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:flutter/widgets.dart';

/// A page's own pull-down refresh, drawn as the main tabs' ([PullToRefresh]):
/// the logo turning and its words, not the plain spinner. For a page outside
/// the home tabs (the account, the notifications, the simplified mode), which
/// reads its own data with [onRefresh].
class LogoRefresh extends StatelessWidget {
  const LogoRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshScope(
    onRefresh: onRefresh,
    child: PullToRefresh(child: child),
  );
}
