import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: SimplifiedStyle.doneGround),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            width: 144,
                            height: 144,
                            decoration: const BoxDecoration(
                              color: SimplifiedStyle.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const ExcludeSemantics(
                              child: Icon(
                                AppIcons.check,
                                size: 72,
                                color: SimplifiedStyle.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            context.tr('simplified_mode.done_title'),
                            style: SimplifiedStyle.head(38),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            saved,
                            textAlign: TextAlign.center,
                            style: SimplifiedStyle.text(
                              SimplifiedStyle.title,
                              weight: AppTextTheme.medium,
                            ),
                          ),
                          // The reading is worth little without what it
                          // means, which is the whole reason to measure.
                          if (verdict case final MeasurementVerdict said)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ExcludeSemantics(
                                    child: Icon(said.level.icon, size: 28),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    said.label,
                                    style: SimplifiedStyle.head(
                                      SimplifiedStyle.headline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
