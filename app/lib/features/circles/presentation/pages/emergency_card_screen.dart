import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:app/features/circles/presentation/widgets/ambulance_button.dart';
import 'package:app/features/circles/presentation/widgets/circle_skeletons.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_body.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_export.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_language_switch.dart';
import 'package:app/features/circles/presentation/widgets/emergency_why_separate.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The emergency card of a circle (CIRCLE-07), as in the handoff: one white
/// card with an ink edge that a stranger can read in a hurry (a paramedic, a
/// school, a neighbour). The red badge, the name and age, the blood type in
/// a dark box, the allergy in a red box, the chronic conditions, the current
/// medicines and the people to call. Under it the ambulance button and why
/// the card is separate from the medical file.
///
/// «عربي / English» switches the card's language; medicine names and typed
/// text stay as written. «تصدير» shares the card as a PDF. The card is
/// read-only. Needs an [EmergencyCardCubit] and a [MedicationsCubit] above
/// it.
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key, this.closeTo = Routes.circle});

  /// Where «رجوع» goes when there is no page under the card to return to
  /// (an address opened directly): the circle tab in the detailed mode,
  /// the simplified home in the simplified mode.
  final String closeTo;

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  /// The picture of the card for the PDF is taken from here.
  final GlobalKey _cardKey = GlobalKey();
  bool _english = false;
  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = context.tr('record_export.failed');
    bool shared;
    try {
      shared = await shareEmergencyCardPdf(
        boundary: _cardKey,
        title: context.tr('circles.card_title'),
      );
    } on Exception {
      shared = false;
    }
    if (!mounted) return;
    setState(() => _exporting = false);
    if (!shared) {
      AppToast.showText(messenger, failed, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EmergencyCardCubit cubit = context.read<EmergencyCardCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmergencyCardCubit, EmergencyCardState>(
          listenWhen: (EmergencyCardState before, EmergencyCardState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, EmergencyCardState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, EmergencyCardState state) {
            final bool ready = state.status == EmergencyCardStatus.ready;
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      BackLink(
                        onPressed: context.canPop()
                            ? () => context.pop()
                            : () => context.go(widget.closeTo),
                      ),
                      const Spacer(),
                      if (ready)
                        TextButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: const Icon(
                            AppIcons.export,
                            size: AppSizes.iconSmall,
                          ),
                          label: Text(context.tr('emergency_card.export')),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('circles.card_title'),
                      style: text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    // Loading, error and content fade into each other.
                    child: ContentSwitcher(
                      stateKey: state.status,
                      child: _body(context, cubit, state),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EmergencyCardCubit cubit,
    EmergencyCardState state,
  ) {
    switch (state.status) {
      case EmergencyCardStatus.loading:
        return const EmergencyCardSkeleton();
      case EmergencyCardStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case EmergencyCardStatus.ready:
        final EmergencyCardText words = EmergencyCardText(
          context,
          english: _english,
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: <Widget>[
            EmergencyLanguageSwitch(
              english: _english,
              onChanged: (bool english) => setState(() => _english = english),
            ),
            const SizedBox(height: AppSpacing.md),
            RepaintBoundary(
              key: _cardKey,
              child: Directionality(
                textDirection: _english ? TextDirection.ltr : TextDirection.rtl,
                child: EmergencyCardBody(
                  card: state.card!,
                  birthDate: state.birthDate,
                  words: words,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AmbulanceButton(),
            const SizedBox(height: AppSpacing.md),
            const EmergencyWhySeparate(),
          ],
        );
    }
  }
}
