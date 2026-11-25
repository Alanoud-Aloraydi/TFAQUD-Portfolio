import 'dart:async';

import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
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
    final SimplifiedMeasurementState state = context
        .read<SimplifiedMeasurementCubit>()
        .state;
    // The task's own kind, where the patient came from a task, so the
    // form opens on the right one and never flickers.
    _form.kind = state.task?.kind;
    // This read makes the cubit, ready at once, before the listener below
    // exists: without this a free reading never chose a kind (no form).
    if (state.status == SimplifiedMeasurementStatus.ready) {
      simplifiedMeasureArrived(_form, state);
    }
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

/// A load or a save that has just finished and left something new to show.
bool simplifiedMeasureSettled(
  SimplifiedMeasurementState before,
  SimplifiedMeasurementState after,
) =>
    (after.status == SimplifiedMeasurementStatus.ready &&
        before.status != SimplifiedMeasurementStatus.ready) ||
    (after.messageKey != null &&
        after.messageKey != before.messageKey &&
        after.status == SimplifiedMeasurementStatus.ready);

/// What that finished load means for [form]: the first one chooses the
/// kind and its conditions, a later one only carries a message.
void simplifiedMeasureArrived(
  SimplifiedMeasureForm form,
  SimplifiedMeasurementState state,
) {
  if (!form.started) {
    // Loaded: the task's kind, else the first kind that can be read.
    form.started = true;
    form.show(state, form.kind ?? state.kinds.firstOrNull);
  } else {
    form.errorKey = state.messageKey;
  }
}
