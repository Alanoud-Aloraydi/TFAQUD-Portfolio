import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The size of a fact's icon tile and of a person's photo beside a fact.
const double _leadingSize = 32;

/// One titled group of a plan card's opened details: «الجدول», «عن الدواء»,
/// «الأشخاص». Related facts sit together in one tinted box, divided by
/// lines, as Apple groups them in its lists, so the eye finds a group
/// first, then the fact.
class PlanFactGroup extends StatelessWidget {
  const PlanFactGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.tokens.textSecondary,
              fontWeight: AppTextTheme.semibold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: AppSemanticColors.background,
            shape: AppRadius.shape(AppRadius.s),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: AppSizes.divider,
                      indent: _leadingSize + AppSpacing.md,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// One fact: an icon tile, a small grey [label] and the [value] in bold,
/// so the value is what stands out. [trailing] sits at the end (a dose,
/// a state); [below] under the value (the days of the week).
class PlanFact extends StatelessWidget {
  const PlanFact({
    super.key,
    required this.icon,
    this.label,
    this.value,
    this.trailing,
    this.below,
  });

  final IconData icon;
  final String? label;
  final String? value;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) => _FactRow(
    leading: ExcludeSemantics(
      child: Container(
        width: _leadingSize,
        height: _leadingSize,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: AppSemanticColors.selectedSurface,
          shape: AppRadius.shape(AppRadius.xs * 2),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.textPrimary,
        ),
      ),
    ),
    label: label,
    value: value,
    trailing: trailing,
    below: below,
  );
}

/// A fact about a person: their photo or avatar beside «أضافه» and their
/// name in bold. Every name the app shows carries its picture.
class PlanPersonFact extends StatelessWidget {
  const PlanPersonFact({
    super.key,
    required this.label,
    required this.name,
    required this.circleId,
    this.accountId,
    this.avatarCode,
  });

  final String label;
  final String name;
  final String circleId;
  final String? accountId;
  final String? avatarCode;

  @override
  Widget build(BuildContext context) => _FactRow(
    leading: PersonPhoto(
      name: name,
      // No account (an old plan): the avatar or the first letter, never
      // the patient's photo.
      photoPath: accountId == null ? '' : personPhotoPath(circleId, accountId),
      avatarCode: avatarCode,
      size: _leadingSize,
    ),
    label: label,
    value: name,
  );
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.leading,
    this.label,
    this.value,
    this.trailing,
    this.below,
  });

  final Widget leading;
  final String? label;
  final String? value;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (label case final String words)
                    Text(
                      words,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  if (value case final String shown)
                    Text(
                      shown,
                      style: text.titleSmall?.copyWith(
                        fontWeight: AppTextTheme.bold,
                      ),
                    ),
                  if (below case final Widget under) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    under,
                  ],
                ],
              ),
            ),
            if (trailing case final Widget end) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              end,
            ],
          ],
        ),
      ),
    );
  }
}
