import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: text.titleSmall?.copyWith(color: AppColors.ink2),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
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
/// [onEdit] is set the whole row is a button with a pencil.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          if (onEdit != null) ...<Widget>[
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.brand),
            const SizedBox(width: 8),
          ],
          Text(label, style: text.bodyMedium?.copyWith(color: AppColors.ink2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: text.bodyLarge,
            ),
          ),
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
    this.color = AppColors.brand,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
