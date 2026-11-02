import 'package:flutter/widgets.dart';

/// Makes the native transparency preference available to custom materials.
class GlassPreferences extends InheritedWidget {
  const GlassPreferences({
    super.key,
    required this.reduceTransparency,
    required super.child,
  });

  final bool reduceTransparency;

  static bool opaqueOf(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<GlassPreferences>();
    return (settings?.reduceTransparency ?? false) ||
        MediaQuery.highContrastOf(context);
  }

  @override
  bool updateShouldNotify(GlassPreferences oldWidget) =>
      reduceTransparency != oldWidget.reduceTransparency;
}
