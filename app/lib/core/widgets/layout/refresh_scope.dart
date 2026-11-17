import 'package:flutter/widgets.dart';

/// How the pages under it read everything they show again: the home shell
/// gives it once, and each main page pulled down from its top uses it
/// ([PullToRefresh]). Every part keeps what it shows until its new data is
/// back, so nothing on the page empties or jumps while it reads.
class RefreshScope extends StatefulWidget {
  const RefreshScope({super.key, required this.onRefresh, required this.child});

  /// The shared data read again; done once it is back, so the spinner can
  /// stop.
  final Future<void> Function() onRefresh;
  final Widget child;

  /// The pull-down of the page around [context]; null where nothing gives
  /// one.
  static Future<void> Function()? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PullScope>()?.pull;

  /// Fires on every pull-down, for a part that reads its own data (the
  /// circle tab's members, the readings of «السجل») to read it again
  /// quietly, in its place. Null where nothing gives one.
  static Listenable? pullsOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PullScope>()?.pulls;

  /// [changes] and every pull-down together, for such a part to follow.
  static Listenable withPulls(BuildContext context, Listenable changes) =>
      Listenable.merge(<Listenable?>[changes, pullsOf(context)]);

  @override
  State<RefreshScope> createState() => _RefreshScopeState();
}

class _RefreshScopeState extends State<RefreshScope> {
  final ValueNotifier<int> _pulls = ValueNotifier<int>(0);

  Future<void> _pull() {
    _pulls.value++;
    return widget.onRefresh();
  }

  @override
  void dispose() {
    _pulls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PullScope(pull: _pull, pulls: _pulls, child: widget.child);
}

class _PullScope extends InheritedWidget {
  const _PullScope({
    required this.pull,
    required this.pulls,
    required super.child,
  });

  final Future<void> Function() pull;
  final Listenable pulls;

  // Both belong to the scope's state and never change.
  @override
  bool updateShouldNotify(_PullScope oldWidget) => false;
}
