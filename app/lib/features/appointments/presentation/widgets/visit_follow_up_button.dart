import 'package:app/core/navigation/routers.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «إضافة موعد متابعة»: starts a new appointment in the same circle.
Widget visitFollowUpButton(BuildContext context) => OutlinedButton.icon(
  onPressed: () => context.push<bool>(
    Routes.newAppointment(context.read<VisitCubit>().circleId),
  ),
  icon: const Icon(CupertinoIcons.calendar),
  label: Text(context.tr('appointments.add_follow_up_appointment')),
);
