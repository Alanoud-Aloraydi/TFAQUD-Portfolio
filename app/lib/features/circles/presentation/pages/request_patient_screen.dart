import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/request_patient_fields.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page that asks a patient who uses the app for a circle (CREAT-04): the
/// patient's phone number and the mode proposed for the patient's app, as
/// two cards that each say what the mode means. The circle is not named
/// here: the patient names it for themself, and the sender sees «دائرة» and
/// the patient's name. Once the request is sent, the same page shows the
/// waiting state (CREAT-05). Needs a [SendCircleRequestCubit] above it.
class RequestPatientScreen extends StatefulWidget {
  const RequestPatientScreen({super.key});

  @override
  State<RequestPatientScreen> createState() => _RequestPatientScreenState();
}

class _RequestPatientScreenState extends State<RequestPatientScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocConsumer<SendCircleRequestCubit, SendCircleRequestState>(
            listenWhen: (
              SendCircleRequestState before,
              SendCircleRequestState after,
            ) => after.sessionEnded && !before.sessionEnded,
            listener: (BuildContext context, SendCircleRequestState state) =>
                context.go(Routes.auth),
            builder: (BuildContext context, SendCircleRequestState state) {
              final sent = state.sent;
              if (sent != null) return RequestSentView(request: sent);
              return RequestPatientForm(phone: _phone, state: state);
            },
          ),
        ),
      ),
    );
  }
}

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
