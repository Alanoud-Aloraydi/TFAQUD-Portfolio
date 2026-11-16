import 'dart:async';

import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_arrival.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_saved.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «تسجيل قياس»: blood pressure or glucose, a big number typed on a big
/// keypad, the optional circumstances, and one save button. The screen
/// holds the typing ([SimplifiedMeasureForm]) and hands it to the page;
/// what the patient typed, what it means and how it is saved each live in
/// their own file.
class SimplifiedMeasureScreen extends StatefulWidget {
  const SimplifiedMeasureScreen({super.key});

  @override
  State<SimplifiedMeasureScreen> createState() =>
      _SimplifiedMeasureScreenState();
}

class _SimplifiedMeasureScreenState extends State<SimplifiedMeasureScreen> {
  final SimplifiedMeasureForm _form = SimplifiedMeasureForm();

  @override
  void initState() {
    super.initState();
    // The task's own kind, where the patient came from a task: known
    // before anything loads, so the form opens on the right one and never
    // flickers from «الضغط» to «السكر».
    _form.kind = context.read<SimplifiedMeasurementCubit>().state.task?.kind;
  }

  @override
  void dispose() {
    _form.note.dispose();
    super.dispose();
  }

  /// The form is plain state, not a cubit: it changed, so redraw.
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimplifiedMeasurementCubit, SimplifiedMeasurementState>(
      listenWhen: simplifiedMeasureSettled,
      listener: (BuildContext context, SimplifiedMeasurementState state) =>
          setState(() => simplifiedMeasureArrived(_form, state)),
      builder: (BuildContext context, SimplifiedMeasurementState state) =>
          simplifiedMeasurePage(
            context,
            state,
            _form,
            onChanged: _refresh,
            onSave: () =>
                unawaited(saveSimplifiedMeasure(context, _form, _refresh)),
          ),
    );
  }
}
