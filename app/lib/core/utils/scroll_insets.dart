import 'package:flutter/widgets.dart';

/// Adds scroll insets helpers to its target type.
extension ScrollInsets on BuildContext {
  /// [base] plus the space taken by the floating top controls and tab bar.
  ///
  /// The shell lets content scroll under its glass bars, and the Scaffold
  /// reports their heights as padding. A list with its own padding must add
  /// them, or its first and last rows would sit under the glass at rest.
  EdgeInsets scrollPadding(EdgeInsets base) {
    final EdgeInsets bars = MediaQuery.paddingOf(this);
    return base.copyWith(
      top: base.top + bars.top,
      bottom: base.bottom + bars.bottom,
    );
  }
}
