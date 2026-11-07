import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A small grey title above a white card, as the account page groups its rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(title),
        SettingsCard(children: children),
      ],
    );
  }
}

/// The small grey header above a settings card, reusable where a page needs
/// just the title without the single-card layout `SettingsSection` assumes.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.inset,
        bottom: AppSpacing.labelGap,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: context.tokens.textSecondary),
        ),
      ),
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
            if (i > 0)
              const Divider(
                height: AppSizes.divider,
                indent: 16,
                endIndent: 16,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A grouped information row with its value below the label on the RTL start.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  textAlign: TextAlign.start,
                  style: text.bodySmall?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  textAlign: ltr ? TextAlign.right : TextAlign.start,
                  textDirection: ltr ? TextDirection.ltr : null,
                  style: text.bodyLarge,
                ),
              ],
            ),
          ),
          if (onEdit != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              AppIcons.pencil,
              size: AppSizes.iconSmall,
              color: context.tokens.textSecondary,
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

/// A row with a label, an optional hint below it, and a switch at the end.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      toggled: value,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: text.bodyLarge),
                  if (hint case final String hint) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hint,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ExcludeSemantics(
              child: CupertinoSwitch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row that is only a text button, such as "تسجيل الخروج".
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppSemanticColors.textPrimary,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
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
