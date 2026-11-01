import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A small grey title above a white card, as the account page groups its rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: text.titleSmall?.copyWith(color: AppColors.slate),
            ),
          ),
        ),
        SettingsCard(children: children),
      ],
    );
  }
}

/// A white card whose rows are separated by thin lines.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppSurfaces.card(),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A row with the label on the start side and the value on the other. When
/// [onEdit] is set the whole row is a button with a pencil at its end, as
/// iOS puts a row's mark at the end: every label starts on the same line,
/// with or without a pencil.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onEdit,
    this.editLabel,
    this.ltr = false,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  /// What a screen reader says for the pencil, for example "تعديل اسم العرض".
  final String? editLabel;

  /// The value is a number (the phone number) and is written left to right.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Text(label, style: text.bodyMedium?.copyWith(color: AppColors.slate)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: text.bodyLarge,
            ),
          ),
          if (onEdit != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              CupertinoIcons.pencil,
              size: AppSizes.iconSmall,
              color: AppColors.slate,
            ),
          ],
        ],
      ),
    );
    if (onEdit == null) return row;
    return Semantics(
      button: true,
      label: editLabel ?? label,
      value: value,
      excludeSemantics: true,
      onTap: onEdit,
      child: InkWell(onTap: onEdit, child: row),
    );
  }
}

/// A row that is only a text button, such as "تسجيل الخروج".
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.ink,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: busy ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: text.titleMedium?.copyWith(color: color),
              ),
            ),
            if (busy)
              const SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
