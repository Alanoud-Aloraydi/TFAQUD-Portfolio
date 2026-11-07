import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/listen_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Records a glucose or blood-pressure reading, in the same sheet shape as
/// the detailed mode's free reading ("القياس الحر"): one modal, a kind
/// picker at the top, the value, and a save button — but with the detailed
/// sheet's extra fields (target range, context, condition, time, note)
/// left out, since the simplified mode keeps content to just the number.
///
/// [lockedKind] fixes the kind with no picker shown, for a known due or
/// missed task; otherwise the picker shows only when both kinds have a
/// target, and the one kind with a target is used silently when only one
/// does.
Future<bool> showSimplifiedMeasurementSheet(
  BuildContext context, {
  required String circleId,
  MeasurementKind? lockedKind,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: GetIt.I<SimplifiedMeasurementCubit>()..load(circleId),
        child: _SimplifiedMeasurementSheet(
          circleId: circleId,
          lockedKind: lockedKind,
        ),
      ),
    ) ??
    false;

class _SimplifiedMeasurementSheet extends StatefulWidget {
  const _SimplifiedMeasurementSheet({required this.circleId, this.lockedKind});

  final String circleId;
  final MeasurementKind? lockedKind;

  @override
  State<_SimplifiedMeasurementSheet> createState() =>
      _SimplifiedMeasurementSheetState();
}

class _SimplifiedMeasurementSheetState
    extends State<_SimplifiedMeasurementSheet> {
  MeasurementKind _kind = MeasurementKind.glucose;
  bool _kindChosen = false;
  final _value = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    if (widget.lockedKind case final kind?) {
      _kind = kind;
      _kindChosen = true;
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    super.dispose();
  }

  /// Picks the kind once loaded, when it was not already locked: both
  /// targets present shows the picker (defaulting to glucose); exactly one
  /// present locks to it silently.
  void _chooseKindFrom(SimplifiedMeasurementState state) {
    if (_kindChosen) return;
    final bool glucose = state.targetFor(MeasurementKind.glucose) != null;
    final bool bp = state.targetFor(MeasurementKind.bp) != null;
    if (bp && !glucose) _kind = MeasurementKind.bp;
    _kindChosen = true;
  }

  List<String> _listenSegments(BuildContext context) => [
    context.tr(
      _kind == MeasurementKind.glucose
          ? 'measurements.glucose'
          : 'measurements.bp',
    ),
    if (_kind == MeasurementKind.glucose)
      context.tr('measurements.value')
    else ...[
      context.tr('measurements.systolic'),
      context.tr('measurements.diastolic'),
    ],
    context.tr('measurements.save_reading'),
  ];

  Future<void> _save() async {
    final cubit = context.read<SimplifiedMeasurementCubit>();
    final bool saved;
    if (_kind == MeasurementKind.glucose) {
      final int? value = int.tryParse(_value.text);
      if (value == null || value < 1 || value > 999) {
        setState(() => _errorKey = 'measurements.invalid_reading');
        return;
      }
      setState(() => _errorKey = null);
      saved = await cubit.recordGlucose(value);
    } else {
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
      saved = await cubit.recordBp(systolic, diastolic);
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorKey = cubit.state.errorKey ?? 'error.unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimplifiedMeasurementCubit, SimplifiedMeasurementState>(
      builder: (context, state) {
        if (state.status == SimplifiedMeasurementStatus.loading) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == SimplifiedMeasurementStatus.failure) {
          return SizedBox(
            height: 160,
            child: Center(
              child: TextButton(
                onPressed: () => context
                    .read<SimplifiedMeasurementCubit>()
                    .load(widget.circleId),
                child: Text(context.tr(state.errorKey ?? 'error.unknown')),
              ),
            ),
          );
        }
        _chooseKindFrom(state);
        final bool pickable =
            widget.lockedKind == null &&
            state.targetFor(MeasurementKind.glucose) != null &&
            state.targetFor(MeasurementKind.bp) != null;
        final bool saving =
            state.saveStatus == SimplifiedMeasurementSaveStatus.saving;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('measurements.record_reading'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListenButton(segments: _listenSegments(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (pickable) ...[
                  GlassSegmentedControl<MeasurementKind>(
                    segments: {
                      MeasurementKind.glucose: context.tr(
                        'measurements.glucose',
                      ),
                      MeasurementKind.bp: context.tr('measurements.bp'),
                    },
                    selected: _kind,
                    onChanged: (value) => setState(() => _kind = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                InsetGroup(
                  children: [
                    InsetBlock(
                      semanticLabel: context.tr(
                        _kind == MeasurementKind.glucose
                            ? 'measurements.glucose'
                            : 'measurements.bp',
                      ),
                      errorText: _errorKey == null
                          ? null
                          : context.tr(_errorKey!),
                      child: _kind == MeasurementKind.glucose
                          ? _valueField(context)
                          : _bpFields(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(context.tr('measurements.save_reading')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _valueField(BuildContext context) => Column(
    children: [
      Text(context.tr('measurements.value')),
      const SizedBox(height: AppSpacing.xs),
      _numberField(context, _value, autofocus: true),
      const SizedBox(height: AppSpacing.xs),
      Text(
        context.tr('measurements.glucose_unit'),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _bpFields(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(context.tr('measurements.systolic')),
                const SizedBox(height: AppSpacing.xs),
                _numberField(context, _systolic, autofocus: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text('/', style: Theme.of(context).textTheme.headlineMedium),
          ),
          Expanded(
            child: Column(
              children: [
                Text(context.tr('measurements.diastolic')),
                const SizedBox(height: AppSpacing.xs),
                _numberField(context, _diastolic),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(context.tr('measurements.bp_unit'), textAlign: TextAlign.center),
    ],
  );

  Widget _numberField(
    BuildContext context,
    TextEditingController controller, {
    bool autofocus = false,
  }) => TextField(
    controller: controller,
    autofocus: autofocus,
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
  );
}
