import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One emergency contact of the medical file: a round letter, the name, the
/// relation and the number, and a pencil that opens the form of the contact.
class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact, this.onEdit});

  final EmergencyContact contact;

  /// Null hides the pencil (a form is open and one contact is edited at a
  /// time).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: CircleAvatar(
              backgroundColor: AppColors.leafTint,
              foregroundColor: AppColors.ink,
              child: Text(
                contact.initial,
                style: text.titleMedium?.copyWith(color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(contact.name, style: text.titleMedium),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: <Widget>[
                    Text(
                      MedicalTexts.relation(context, contact),
                      style: text.bodyMedium?.copyWith(color: AppColors.slate),
                    ),
                    Text(
                      MedicalTexts.phone(contact),
                      textDirection: TextDirection.ltr,
                      style: text.bodyMedium?.copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(CupertinoIcons.pencil, color: AppColors.ink),
              tooltip: context.tr(
                'circles.contact_edit_action',
                args: <String>[contact.name],
              ),
            ),
        ],
      ),
    );
  }
}
