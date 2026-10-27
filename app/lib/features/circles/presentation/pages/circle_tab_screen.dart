import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:easy_localization/easy_localization.dart';
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: <Widget>[CircleCard(circle: circle)],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.warningTint,
                  child: Text(
                    initial,
                    style: text.titleLarge?.copyWith(
                      color: AppColors.warningInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(circle.name, style: text.headlineSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(Routes.medicalFile(circle.id)),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(context.tr('circles.file_title')),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(Routes.emergencyCard(circle.id)),
                  icon: const Icon(Icons.favorite_border),
                  label: Text(context.tr('circles.card_title')),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.dangerInk,
                    side: const BorderSide(color: AppColors.danger),
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
