import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
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

/// The yellow note above the send button: the patient is asked, and nothing is
/// created without the patient's agreement. The icon keeps the colour from being
/// the only signal.
class RequestPatientNotice extends StatelessWidget {
  const RequestPatientNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            NoticeIcons.info,
            size: AppSizes.iconSmall,
            color: context.tokens.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
