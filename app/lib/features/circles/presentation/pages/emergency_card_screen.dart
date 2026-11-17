import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_export.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_page.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final bool shared = await shareEmergencyCardSafely(
      boundary: _cardKey,
      title: context.tr('circles.card_title'),
    );
    if (!mounted) return;
    setState(() => _exporting = false);
    if (!shared) AppToast.showText(messenger, failed, kind: ToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmergencyCardCubit, EmergencyCardState>(
          listenWhen: (EmergencyCardState before, EmergencyCardState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, EmergencyCardState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, EmergencyCardState state) =>
              EmergencyCardPage(
                state: state,
                closeTo: widget.closeTo,
                cardKey: _cardKey,
                english: _english,
                onLanguage: (bool english) =>
                    setState(() => _english = english),
                onExport: _exporting ? null : _export,
              ),
        ),
      ),
    );
  }
}
