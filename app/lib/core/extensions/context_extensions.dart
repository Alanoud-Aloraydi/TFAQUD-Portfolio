import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/loading/loading_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

extension ContextExtensions on BuildContext {
  // Snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      // Ink background from the theme. The icon tells an error from a
      // confirmation, so the meaning never rests on color alone.
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle
                  : CupertinoIcons.checkmark_circle,
              color: AppSemanticColors.surfaceContent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void showLoading() {
    LoadingWidgetOverlay().show(this);
  }

  void hideLoading() {
    LoadingWidgetOverlay().hide();
  }

  void showBottomSheet({required Widget widget, double? height, Color? color}) {
    showModalBottomSheet(
      context: this,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      clipBehavior: .hardEdge,
      builder: (context) => Container(
        padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 16),
        height: height ?? 75.h,
        width: 100.w,
        color: color,
        child: widget,
      ),
    );
  }
}
