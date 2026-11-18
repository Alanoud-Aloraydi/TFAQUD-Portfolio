import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/account/presentation/widgets/sent_request_line.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The app mode the request proposed, as a line of the sheet.
class SentRequestModeLine extends StatelessWidget {
  const SentRequestModeLine({super.key, required this.mode});

  final CircleAppMode mode;

  @override
  Widget build(BuildContext context) {
    return SentRequestLine(
      label: context.tr('circles.app_mode'),
      child: StatusBadge(
        text: context.tr(
          mode == CircleAppMode.detailed
              ? 'circles.mode_detailed'
              : 'circles.mode_simplified',
        ),
        tone: StatusTone.success,
      ),
    );
  }
}
