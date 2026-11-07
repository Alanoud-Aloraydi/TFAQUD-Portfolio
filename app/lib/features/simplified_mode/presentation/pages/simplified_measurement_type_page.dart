import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/listen_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_scale.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Lets the patient choose which measurement to record. Skips itself and
/// opens that kind's screen directly when the plan only has one kind.
class SimplifiedMeasurementTypePage extends StatefulWidget {
  const SimplifiedMeasurementTypePage({super.key, required this.circleId});

  final String circleId;

  @override
  State<SimplifiedMeasurementTypePage> createState() =>
      _SimplifiedMeasurementTypePageState();
}

class _SimplifiedMeasurementTypePageState
    extends State<SimplifiedMeasurementTypePage> {
  bool _skipped = false;

  void _openGlucose() =>
      context.pushReplacement(Routes.simplifiedGlucoseReading(widget.circleId));

  void _openBp() =>
      context.pushReplacement(Routes.simplifiedBpReading(widget.circleId));

  @override
  Widget build(BuildContext context) {
    return SimplifiedScale(
      child: Scaffold(
        body: SafeArea(
          child:
              BlocConsumer<
                SimplifiedMeasurementCubit,
                SimplifiedMeasurementState
              >(
                listener: (context, state) {
                  if (_skipped ||
                      state.status != SimplifiedMeasurementStatus.ready) {
                    return;
                  }
                  final bool glucose =
                      state.targetFor(MeasurementKind.glucose) != null;
                  final bool bp = state.targetFor(MeasurementKind.bp) != null;
                  if (glucose && !bp) {
                    _skipped = true;
                    _openGlucose();
                  } else if (bp && !glucose) {
                    _skipped = true;
                    _openBp();
                  }
                },
                builder: (context, state) {
                  if (state.status == SimplifiedMeasurementStatus.loading ||
                      _skipped) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == SimplifiedMeasurementStatus.failure) {
                    return Center(
                      child: TextButton(
                        onPressed: () => context
                            .read<SimplifiedMeasurementCubit>()
                            .load(widget.circleId),
                        child: Text(
                          context.tr(state.errorKey ?? 'error.unknown'),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StepHeader(
                          title: context.tr(
                            'simplified_mode.choose_measurement',
                          ),
                          onClose: () => context.pop(),
                          trailing: ListenButton(
                            segments: [
                              context.tr('simplified_mode.choose_measurement'),
                              context.tr('measurements.glucose'),
                              context.tr('measurements.bp'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _ChoiceCard(
                          label: context.tr('measurements.glucose'),
                          icon: CupertinoIcons.drop,
                          onTap: _openGlucose,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChoiceCard(
                          label: context.tr('measurements.bp'),
                          icon: CupertinoIcons.heart,
                          onTap: _openBp,
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSemanticColors.surfaceContent,
      borderRadius: BorderRadius.circular(AppRadius.l),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.l),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppSemanticColors.actionPrimary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward),
            ],
          ),
        ),
      ),
    );
  }
}
