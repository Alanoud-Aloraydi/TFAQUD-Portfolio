import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/presentation/pages/done/simplified_done_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// «تم، شكرًا»: says exactly what was saved, and stays until the patient
/// goes back home.
class SimplifiedDoneScreen extends StatelessWidget {
  const SimplifiedDoneScreen({super.key, required this.message});

  final SimplifiedDoneMessage message;

  @override
  Widget build(BuildContext context) {
    final String saved = message.text(context);
    return _screen(context, saved, message.verdict(context));
  }

  Widget _screen(
    BuildContext context,
    String saved,
    MeasurementVerdict? verdict,
  ) {
    return Scaffold(
      backgroundColor: SimplifiedColors.doneGround,
      body: SizedBox.expand(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SimplifiedDoneContent(saved: saved, verdict: verdict),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SimplifiedStyle.page,
                  0,
                  SimplifiedStyle.page,
                  36,
                ),
                child: SimplifiedButton(
                  label: context.tr('simplified_mode.back_home'),
                  tone: SimplifiedButtonTone.dark,
                  onPressed: () => context.go(Routes.simplifiedMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
