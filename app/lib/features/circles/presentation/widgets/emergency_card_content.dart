import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:app/features/circles/presentation/widgets/ambulance_button.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_body.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_failure.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_language_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the page holds for one state of the card: the skeleton, the retry,
/// or the card itself in the language chosen, with the ambulance button.
class EmergencyCardContent extends StatelessWidget {
  const EmergencyCardContent({
    super.key,
    required this.state,
    required this.cardKey,
    required this.english,
    required this.onLanguage,
  });

  final EmergencyCardState state;

  /// The picture of the card for the PDF is taken from here.
  final GlobalKey cardKey;
  final bool english;
  final ValueChanged<bool> onLanguage;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case EmergencyCardStatus.loading:
        return const EmergencyCardSkeleton();
      case EmergencyCardStatus.failure:
        return EmergencyCardFailure(
          messageKey: state.messageKey,
          onRetry: context.read<EmergencyCardCubit>().load,
        );
      case EmergencyCardStatus.ready:
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: <Widget>[
            EmergencyLanguageSwitch(english: english, onChanged: onLanguage),
            const SizedBox(height: AppSpacing.md),
            RepaintBoundary(
              key: cardKey,
              child: Directionality(
                textDirection: english ? TextDirection.ltr : TextDirection.rtl,
                child: EmergencyCardBody(
                  card: state.card!,
                  birthDate: state.birthDate,
                  words: EmergencyCardText(context, english: english),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AmbulanceButton(),
          ],
        );
    }
  }
}
