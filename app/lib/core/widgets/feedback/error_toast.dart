import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:flutter/widgets.dart';

/// Shows [errorKey] as an error toast each time it appears. For an error
/// that belongs to no field (the network, the server): an error of a field
/// is shown under that field, not at the bottom of the page.
class ErrorToast extends StatefulWidget {
  const ErrorToast({super.key, required this.errorKey, required this.child});

  /// The translation key of the error, or null.
  final String? errorKey;

  final Widget child;

  @override
  State<ErrorToast> createState() => _ErrorToastState();
}

class _ErrorToastState extends State<ErrorToast> {
  @override
  void didUpdateWidget(ErrorToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? key = widget.errorKey;
    if (key == null || key == oldWidget.errorKey) return;
    // After the frame: a toast cannot be shown while the page builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppToast.show(context, key, kind: ToastKind.error);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
