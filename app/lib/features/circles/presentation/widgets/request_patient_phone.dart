import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The patient's number on the request page. A refusal of the number (one's
/// own number, or a person with a circle of their own) is said under it;
/// any other refusal of the request is a toast.
class RequestPatientPhone extends StatelessWidget {
  const RequestPatientPhone({
    super.key,
    required this.controller,
    required this.state,
    required this.cubit,
  });

  final TextEditingController controller;
  final SendCircleRequestState state;
  final SendCircleRequestCubit cubit;

  /// The refusals that are about the number itself.
  static const Set<String> _numberKeys = <String>{
    'circles.self_request',
    'circles.patient_has_circle',
  };

  @override
  Widget build(BuildContext context) {
    final String? key = state.errorKey;
    final String? numberError = _numberKeys.contains(key)
        ? context.tr(key!)
        : null;
    return ErrorToast(
      errorKey: numberError == null ? key : null,
      child: PhoneField(
        controller: controller,
        label: context.tr('circles.patient_phone_label'),
        autofocus: false,
        showError: state.showErrors && !state.phoneValid,
        error: numberError,
        onChanged: (String typed) =>
            cubit.phoneChanged(ArabicDigits.digitsOnly(typed)),
      ),
    );
  }
}

/// «الوضع المقترح» and the two modes a request can propose for the
/// patient's app, as cards that each say what the mode means.
class RequestModeChoices extends StatelessWidget {
  const RequestModeChoices({
    super.key,
    required this.mode,
    required this.onChoose,
  });

  final CircleAppMode mode;
  final ValueChanged<CircleAppMode> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.proposed_mode')),
        const SizedBox(height: AppSpacing.sm),
        // Both modes and what each one means, on the screen at once.
        ChoiceCard(
          icon: PeopleIcons.user,
          title: context.tr('circles.mode_detailed'),
          hint: context.tr('circles.mode_detailed_hint'),
          selected: mode == CircleAppMode.detailed,
          onTap: () => onChoose(CircleAppMode.detailed),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceCard(
          icon: CareIcons.heart,
          title: context.tr('circles.mode_simplified'),
          hint: context.tr('circles.mode_simplified_hint'),
          selected: mode == CircleAppMode.simplified,
          onTap: () => onChoose(CircleAppMode.simplified),
        ),
      ],
    );
  }
}
