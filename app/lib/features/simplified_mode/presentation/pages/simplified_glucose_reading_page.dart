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

/// Records one glucose reading: a single number, nothing else.
class SimplifiedGlucoseReadingPage extends StatefulWidget {
  const SimplifiedGlucoseReadingPage({super.key});

  @override
  State<SimplifiedGlucoseReadingPage> createState() =>
      _SimplifiedGlucoseReadingPageState();
}

class _SimplifiedGlucoseReadingPageState
    extends State<SimplifiedGlucoseReadingPage> {
  final _value = TextEditingController();
  String? _errorKey;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? value = int.tryParse(_value.text);
    if (value == null || value < 1 || value > 999) {
      setState(() => _errorKey = 'measurements.invalid_reading');
      return;
    }
    setState(() => _errorKey = null);
    final bool saved = await context
        .read<SimplifiedMeasurementCubit>()
        .recordGlucose(value);
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
                  title: context.tr('measurements.glucose'),
                  onBack: () => context.pop(),
                  trailing: ListenButton(
                    segments: [
                      context.tr('measurements.glucose'),
                      context.tr('measurements.value'),
                      context.tr('measurements.save_reading'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                InsetGroup(
                  children: [
                    InsetBlock(
                      semanticLabel: context.tr('measurements.glucose'),
                      errorText: _errorKey == null
                          ? null
                          : context.tr(_errorKey!),
                      child: Column(
                        children: [
                          Text(context.tr('measurements.value')),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _value,
                            autofocus: true,
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr('measurements.glucose_unit'),
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
}
