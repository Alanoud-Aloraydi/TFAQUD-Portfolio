import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/large_title.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The "الدائرة" tab (CIRCLE-01). It shows the card of the selected circle
/// with the two buttons that open its medical file and its emergency card.
/// Needs the [HomeCubit] of the home screen above it.
class CircleTabScreen extends StatelessWidget {
  const CircleTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        final String? selectedId = state.selectedCircleId;
        CareCircleSummary? circle;
        for (final CareCircleSummary candidate
            in state.data?.circles ?? const <CareCircleSummary>[]) {
          if (candidate.id == selectedId) circle = candidate;
        }
        if (circle == null) return const SizedBox.shrink();
        return ListView(
          padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
          children: <Widget>[
            LargeTitle(title: context.tr('tab.circle')),
            CircleCard(circle: circle),
          ],
        );
      },
    );
  }
}

/// The card of a circle: its name, and the buttons "الملف الطبي" and
/// "بطاقة الطوارئ".
class CircleCard extends StatelessWidget {
  const CircleCard({super.key, required this.circle});

  final CareCircleSummary circle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = circle.name.trim();
    final String initial = name.isEmpty
        ? ''
        : String.fromCharCode(name.runes.first);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.leafTint,
                  child: Text(
                    initial,
                    style: text.titleLarge?.copyWith(color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(circle.name, style: text.headlineSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(Routes.medicalFile(circle.id)),
                  icon: const Icon(CupertinoIcons.doc_text),
                  label: Text(context.tr('circles.file_title')),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.stone),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(Routes.emergencyCard(circle.id)),
                  icon: const Icon(CupertinoIcons.heart),
                  label: Text(context.tr('circles.card_title')),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.stone),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
