import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/request_patient_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The request before it is sent: the patient's number, the proposed mode
/// and the notice, scrolling, over «إرسال الطلب» at the bottom.
class RequestPatientForm extends StatelessWidget {
  const RequestPatientForm({
    super.key,
    required this.phone,
    required this.state,
  });

  /// The typed number, kept by the page so it outlives a rebuild.
  final TextEditingController phone;
  final SendCircleRequestState state;

  @override
  Widget build(BuildContext context) {
    final SendCircleRequestCubit cubit = context.read<SendCircleRequestCubit>();
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: RequestPatientFields(phone: phone, state: state),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('circles.send_request'),
          isLoading: state.status == SendStatus.sending,
          onPressed: () => cubit.send(),
        ),
      ],
    );
  }
}
