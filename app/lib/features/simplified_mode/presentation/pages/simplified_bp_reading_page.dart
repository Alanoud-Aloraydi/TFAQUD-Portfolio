import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/listen_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Records one blood-pressure reading: systolic over diastolic.
class SimplifiedBpReadingPage extends StatefulWidget {
  const SimplifiedBpReadingPage({super.key});

  @override
  State<SimplifiedBpReadingPage> createState() =>
      _SimplifiedBpReadingPageState();
}

class _SimplifiedBpReadingPageState extends State<SimplifiedBpReadingPage> {
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  String? _errorKey;

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? systolic = int.tryParse(_systolic.text);
    final int? diastolic = int.tryParse(_diastolic.text);
    if (systolic == null ||
        diastolic == null ||
        systolic < 1 ||
        systolic > 999 ||
        diastolic < 1 ||
        diastolic > 999 ||
        systolic <= diastolic) {
      setState(() => _errorKey = 'measurements.invalid_reading');
      return;
    }
    setState(() => _errorKey = null);
    final bool saved = await context
        .read<SimplifiedMeasurementCubit>()
        .recordBp(systolic, diastolic);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _errorKey =
            context.read<SimplifiedMeasurementCubit>().state.errorKey ??
            'error.unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool saving =
        context.watch<SimplifiedMeasurementCubit>().state.saveStatus ==
        SimplifiedMeasurementSaveStatus.saving;
    return SimplifiedScale(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepHeader(
                  title: context.tr('measurements.bp'),
                  onBack: () => context.pop(),
                  trailing: ListenButton(
                    segments: [
                      context.tr('measurements.bp'),
                      context.tr('measurements.systolic'),
                      context.tr('measurements.diastolic'),
                      context.tr('measurements.save_reading'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                InsetGroup(
                  children: [
                    InsetBlock(
                      semanticLabel: context.tr('measurements.bp'),
                      errorText: _errorKey == null
                          ? null
                          : context.tr(_errorKey!),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  context,
                                  _systolic,
                                  context.tr('measurements.systolic'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Text(
                                  '/',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                              Expanded(
                                child: _field(
                                  context,
                                  _diastolic,
                                  context.tr('measurements.diastolic'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr('measurements.bp_unit'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(context.tr('measurements.save_reading')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          autofocus: controller == _systolic,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
          inputFormatters: [
            const WesternDigitsFormatter(),
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: AppSemanticColors.surfaceContent,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }
}
