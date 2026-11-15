import 'package:flutter/foundation.dart';

/// The item the notification just tapped is about (its key, as
/// reminders/item_keys.dart names it), so the page the tap opens can show
/// it: «اليوم» opens the prayer period it is in and brings its row into
/// view, the bell opens the tab it is in. One for the whole app.
class TapFocus extends ChangeNotifier {
  TapFocus({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// The one the app's pages read.
  static final TapFocus instance = TapFocus();

  /// How long after the tap its item is still brought into view, while
  /// the page reads its data.
  static const Duration waitFor = Duration(minutes: 2);

  /// How long the item stays outlined once it is in view.
  static const Duration outlineFor = Duration(seconds: 3);

  final DateTime Function() _now;
  String? _key;
  DateTime? _at;
  bool _claimed = false;

  /// The item of the last tapped notification, until another is tapped.
  String? get key => _key;

  /// The tapped item while it is still to be brought into view.
  String? get waiting {
    final DateTime? at = _at;
    if (_claimed || at == null || _now().difference(at) > waitFor) return null;
    return _key;
  }

  /// A notification about [key] was tapped (null: nothing in particular).
  void show(String? key) {
    _key = key;
    _at = _now();
    _claimed = false;
    notifyListeners();
  }

  /// Whether [key] is the item to bring into view now: true once per tap,
  /// to the first that asks, and only for [waitFor] after the tap.
  bool claim(String key) {
    if (waiting != key) return false;
    _claimed = true;
    return true;
  }
}
