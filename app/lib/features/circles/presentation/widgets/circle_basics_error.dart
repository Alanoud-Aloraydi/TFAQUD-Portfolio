import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/feedback/error_toast.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_fields.dart';
import 'package:flutter/material.dart';

/// Why the last try to create the circle was refused, as a toast. A refusal
/// of the birth date is shown under its field while the page asks for it
/// ([CircleBasicsFields]).
class CircleBasicsError extends StatelessWidget {
  const CircleBasicsError({super.key, required this.state});

  final CreateCircleState state;

  @override
  Widget build(BuildContext context) {
    final String? key = state.errorKey;
    final bool underField =
        isBirthDateError(key) && CircleBasicsFields.shown(state);
    return ErrorToast(
      errorKey: underField ? null : key,
      child: const SizedBox.shrink(),
    );
  }
}
