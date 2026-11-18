import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/request_patient_form.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
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
