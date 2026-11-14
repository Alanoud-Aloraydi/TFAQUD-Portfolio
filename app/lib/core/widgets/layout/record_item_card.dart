import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_item_header.dart';
import 'package:flutter/material.dart';

/// The card of one item in «السجل» (a medicine, a reading): the same shell
/// as a plan card (radius, border, padding), with the header, optional
/// [body] parts under it, and the whole card one tap target when [onTap] is
/// set. A card that wants a look ([attention], a reading outside its
/// target) is tinted yellow.
class RecordItemCard extends StatelessWidget {
  const RecordItemCard({
    super.key,
    required this.leading,
    required this.title,
    required this.status,
    this.subtitle,
    this.body = const <Widget>[],
    this.onTap,
    this.attention = false,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget status;
  final List<Widget> body;
  final VoidCallback? onTap;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = AppRadius.shape(
      AppRadius.m,
      side: const BorderSide(color: AppSemanticColors.borderSubtle),
    );
    return Material(
      color: attention
          ? AppSemanticColors.surfaceAttention
          : AppSemanticColors.surfaceContent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppItemCard.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PlanItemHeader(
                leading: leading,
                title: title,
                subtitle: subtitle,
                status: status,
              ),
              for (final Widget part in body) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                part,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
