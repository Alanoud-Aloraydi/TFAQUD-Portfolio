import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/simplified_voice.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/simplified_mode/presentation/simplified_speech.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// What «تم، شكرًا» says was saved, exactly.
sealed class SimplifiedDoneMessage {
  const SimplifiedDoneMessage();

  /// «سجّلنا أنك أخذت ميتفورمين · 6:04 مساءً».
  const factory SimplifiedDoneMessage.doseTaken(String name, DateTime at) =
      _DoseTaken;

  /// «سجّلنا قياس السكر: 112».
  const factory SimplifiedDoneMessage.glucose(int value) = _Glucose;

  /// «سجّلنا الضغط: 127/80».
  const factory SimplifiedDoneMessage.bloodPressure(int upper, int lower) =
      _BloodPressure;

  String text(BuildContext context);
}

class _DoseTaken extends SimplifiedDoneMessage {
  const _DoseTaken(this.name, this.at);

  final String name;
  final DateTime at;

  @override
  String text(BuildContext context) {
    final DateTime wall = riyadhNow(at);
    final String time =
        '${wall.hour}:${wall.minute.toString().padLeft(2, '0')}';
    return context.tr(
      'simplified_mode.done_dose',
      args: <String>[name, simplifiedTime(context, time)],
    );
  }
}

class _Glucose extends SimplifiedDoneMessage {
  const _Glucose(this.value);

  final int value;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_glucose', args: <String>['$value']);
}

class _BloodPressure extends SimplifiedDoneMessage {
  const _BloodPressure(this.upper, this.lower);

  final int upper;
  final int lower;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_bp', args: <String>['$upper', '$lower']);
}

/// The parts of the screen «استماع» reads and marks, in their order.
enum _Part { message, home }

/// «تم، شكرًا»: says exactly what was saved, and stays until the patient
/// goes back home.
class SimplifiedDoneScreen extends StatelessWidget {
  const SimplifiedDoneScreen({super.key, required this.message});

  final SimplifiedDoneMessage message;

  @override
  Widget build(BuildContext context) {
    final String saved = message.text(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: SimplifiedStyle.doneGround),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(SimplifiedStyle.page),
                  child: ListenButton(
                    parts: <SpokenPart>[
                      (
                        id: _Part.message,
                        text: sentences(<String>[
                          context.tr('simplified_mode.done_title'),
                          saved,
                        ]),
                      ),
                      (
                        id: _Part.home,
                        text: context.tr('simplified_mode.back_home'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ListenTarget(
                        id: _Part.message,
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 144,
                              height: 144,
                              decoration: const BoxDecoration(
                                color: SimplifiedStyle.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.check,
                                size: 72,
                                color: SimplifiedStyle.ink,
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
                          ],
                        ),
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
                child: ListenTarget(
                  id: _Part.home,
                  radius: SimplifiedStyle.action / 2,
                  child: SimplifiedButton(
                    label: context.tr('simplified_mode.back_home'),
                    tone: SimplifiedButtonTone.dark,
                    onPressed: () => context.go(Routes.simplifiedMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
