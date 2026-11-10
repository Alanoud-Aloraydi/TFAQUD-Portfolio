import 'package:flutter/widgets.dart';

/// Makes the opaque-glass choice (`AppAccessibility.reduceTransparency`: the
/// iOS Reduce Transparency setting, or an Android phone too old for a smooth
/// blur) available to custom materials, with Increase Contrast.
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
