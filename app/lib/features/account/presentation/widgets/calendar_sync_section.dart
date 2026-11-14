import 'package:app/features/account/presentation/widgets/calendar_sync_circle_list.dart';
import 'package:flutter/widgets.dart';

/// One circle in a [CalendarSyncCircleList]: its id, the name shown, and a
/// small picture before the name (the patient's photo).
typedef CalendarSyncCircle = ({String id, String name, Widget? leading});
