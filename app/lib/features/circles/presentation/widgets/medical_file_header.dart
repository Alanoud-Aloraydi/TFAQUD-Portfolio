import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The way back, the page's name, and the pencil «تعديل» that opens the
/// edit page once the file is loaded.
class MedicalFileHeader extends StatelessWidget {
  const MedicalFileHeader({
    super.key,
    required this.canEdit,
    required this.onEdit,
  });

  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      BackLink(
        onPressed: context.canPop()
            ? () => context.pop()
            : () => context.go(Routes.circle),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                context.tr('circles.file_title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          if (canEdit)
            EditAction(
              onPressed: onEdit,
              tooltip: context.tr('circles.file_edit_title'),
            ),
        ],
      ),
    ],
  );
}
