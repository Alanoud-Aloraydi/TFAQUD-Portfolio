import 'dart:async';

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:flutter/widgets.dart';

/// A form row with its error under it ([InsetRowError]). When an error
/// appears, the row scrolls into view, so it is seen where it belongs and
/// not at the bottom of the page.
class FieldWithError extends StatefulWidget {
  const FieldWithError({super.key, required this.child, this.error})
    : _draws = true;

  /// Only scrolls: [child] shows [error] itself, inside its own card.
  const FieldWithError.reveal({super.key, required this.child, this.error})
    : _draws = false;

  final Widget child;

  /// The translated error, or null.
  final String? error;

  final bool _draws;

  @override
  State<FieldWithError> createState() => _FieldWithErrorState();
}

class _FieldWithErrorState extends State<FieldWithError> {
  @override
  void didUpdateWidget(FieldWithError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error == null || widget.error == oldWidget.error) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: AppMotion.formScroll,
          alignment: 0.3,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? error = widget.error;
    if (!widget._draws) return widget.child;
    // Always the column, so the field keeps its focus as the error goes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[widget.child, if (error != null) InsetRowError(error)],
    );
  }
}
