import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/request_mode_choices.dart';
import 'package:app/features/circles/presentation/widgets/request_patient_notice.dart';
import 'package:app/features/circles/presentation/widgets/request_patient_phone.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The fields of the request: header, the patient's number, the proposed mode
/// and the notice.
class RequestPatientFields extends StatelessWidget {
  const RequestPatientFields({
    super.key,
    required this.phone,
    required this.state,
  });

  final TextEditingController phone;
  final SendCircleRequestState state;

  @override
  Widget build(BuildContext context) {
    final SendCircleRequestCubit cubit = context.read<SendCircleRequestCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.request_title'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        RequestPatientPhone(controller: phone, state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.xl),
        RequestModeChoices(mode: state.mode, onChoose: cubit.chooseMode),
        const SizedBox(height: AppSpacing.xl),
        RequestPatientNotice(text: context.tr('circles.request_notice')),
      ],
    );
  }
}
