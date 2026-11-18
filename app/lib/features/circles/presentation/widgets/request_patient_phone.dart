import 'package:app/core/feedback/error_toast.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
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
