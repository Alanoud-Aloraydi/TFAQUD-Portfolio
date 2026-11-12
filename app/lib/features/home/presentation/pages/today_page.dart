import 'dart:async';

import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/home/presentation/widgets/today_content.dart';
import 'package:app/features/home/presentation/widgets/today_header.dart';
import 'package:flutter/material.dart';

/// «اليوم»: the greeting, what needs attention, the next task and the day's
/// schedule by prayer period, all on the patient's clock.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectedCircleBuilder(
    builder: (context, circle) => SingleChildScrollView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TodayHeader(now: PatientClockScope.of(context).now()),
          const SizedBox(height: AppSpacing.xl),
          TodayContent(
            circleId: circle.id,
            // Recording is open to a member who edits any area.
            canManage: circle.canRecord,
            onAdd: circle.canRecord
                ? () => showHomeAddSheet(context, circle: circle)
                : null,
          ),
        ],
      ),
    ),
  );
}
