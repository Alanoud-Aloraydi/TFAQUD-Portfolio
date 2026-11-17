import 'package:flutter/widgets.dart';

/// How the pages under it read everything they show again: the home shell
/// gives it once, and each main page pulled down from its top uses it
/// ([PullToRefresh]).
class RefreshScope extends InheritedWidget {
  const RefreshScope({
    super.key,
    required this.onRefresh,
    required super.child,
  });

  /// Done once the data is back, so the spinner can stop.
  final Future<void> Function() onRefresh;

  /// The nearest refresh above [context]; null where nothing gives one.
  static Future<void> Function()? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RefreshScope>()?.onRefresh;

  @override
  bool updateShouldNotify(RefreshScope oldWidget) =>
      onRefresh != oldWidget.onRefresh;
}
