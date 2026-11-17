import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The shape both circle-naming pages have: what they ask, scrolling, over
/// «إنشاء» at the bottom.
class CircleBasicsFrame extends StatelessWidget {
  const CircleBasicsFrame({
    super.key,
    required this.state,
    required this.onCreate,
    required this.children,
  });

  final CreateCircleState state;
  final VoidCallback onCreate;

  /// What this page asks, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: context.tr('circles.create'),
            isLoading: state.busy,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}
