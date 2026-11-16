import 'package:app/core/navigation/routers.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حضرت» on [visit]: marks it attended, as the family's same button does
/// in the detailed mode, then says so on «تم، يعطيك العافية» with its
/// [title]. When it was not written, the screen stays and the mode's
/// message says why.
Future<void> attendSimplifiedVisit(
  BuildContext context,
  CareAppointment visit,
  String title,
) async {
  final SimplifiedModeCubit cubit = context.read<SimplifiedModeCubit>();
  if (!await cubit.attendAppointment(visit) || !context.mounted) return;
  context.pushReplacement(
    Routes.simplifiedDone,
    extra: SimplifiedDoneMessage.visitAttended(title),
  );
}
