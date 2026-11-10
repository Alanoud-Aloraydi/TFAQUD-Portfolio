import 'dart:convert';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show ReminderCircle, SnoozedTask, TaskSnooze;
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// One event on the fake calendar.
typedef _Event = ({
  String title,
  DateTime start,
  bool repeats,
  String? note,
  String? place,
  List<Duration>? reminders,
  String? zone,
});

/// The phone's calendar, in memory.
class _Calendar extends Fake implements DeviceCalendar {
  final Map<String, _Event> events = <String, _Event>{};
  int _next = 0;

  CalendarPermissionStatus status = CalendarPermissionStatus.granted;

  /// What the person answers when asked for full access.
  CalendarPermissionStatus answer = CalendarPermissionStatus.granted;
  int asked = 0;

  @override
  AutoPermissionMode? autoPermissions;

  /// The calendar gives an event another id, as a synced account can.
  void renumber(String id) {
    events['moved-$id'] = events.remove(id)!;
  }

  @override
  Future<CalendarPermissionStatus> hasPermissions() async => status;

  @override
  Future<CalendarPermissionStatus> requestPermissions({
    CalendarAccessLevel level = CalendarAccessLevel.full,
  }) async {
    asked++;
    return status = answer;
  }

  @override
  Future<String> createEvent({
    String? calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? location,
    String? url,
    String? timeZone,
    EventAvailability availability = EventAvailability.busy,
    RecurrenceRule? recurrenceRule,
    List<Duration>? reminders,
    EventOptionsAndroid? android,
  }) async {
    final String id = 'event-${_next++}';
    events[id] = (
      title: title,
      start: startDate,
      repeats: recurrenceRule != null,
      note: description,
      place: location,
      reminders: reminders,
      zone: timeZone,
    );
    return id;
  }

  void _remove(String id, {required bool repeats}) {
    if (status != CalendarPermissionStatus.granted) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.permissionDenied,
        message: 'full access needed',
      );
    }
    final _Event? event = events[id];
    if (event == null) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.notFound,
        message: 'no such event',
      );
    }
    expect(event.repeats, repeats);
    events.remove(id);
  }

  @override
  Future<void> deleteEvent({required String instanceId}) async =>
      _remove(instanceId, repeats: false);

  @override
  Future<void> deleteRecurring(String instanceId, EventSpan span) async {
    expect(span, EventSpan.allEvents);
    _remove(instanceId, repeats: true);
  }

  @override
  Future<List<Event>> listEvents(
    DateTime startDate,
    DateTime endDate, {
    List<String>? calendarIds,
  }) async => <Event>[
    for (final MapEntry<String, _Event> entry in events.entries)
      if (!entry.value.start.isBefore(startDate) &&
          entry.value.start.isBefore(endDate))
        Event(
          eventId: entry.key,
          instanceId: entry.key,
          calendarId: 'calendar',
          title: entry.value.title,
          startDate: entry.value.start,
          endDate: entry.value.start.add(const Duration(hours: 1)),
          isAllDay: false,
          availability: EventAvailability.free,
          status: EventStatus.confirmed,
          isRecurring: entry.value.repeats,
        ),
  ];
}

class _Medications extends Fake implements MedicationsRepositoryDomain {
  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) async => const Success(<MedicationPlan>[]);
}

class _Measurements extends Fake implements MeasurementRepository {
  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async =>
      const <MeasurementPlan>[];
}

class _Appointments extends Fake implements AppointmentRepository {
  final Map<String, List<CareAppointment>> visits =
      <String, List<CareAppointment>>{};
  bool offline = false;

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async {
    if (offline) throw Exception('offline');
    return visits[circleId] ?? const <CareAppointment>[];
  }
}

/// A diabetes follow-up in three days at [time], at «الحبيب».
CareAppointment _visit({String id = 'a-1', String time = '16:30'}) {
  final DateTime day = DateTime.now().add(const Duration(days: 3));
  return CareAppointment(
    id: id,
    specialty: 'diabetes',
    kind: AppointmentKind.followUp,
    otherKind: null,
    scheduledOn: DateTime(day.year, day.month, day.day),
    time: time,
    place: 'الحبيب',
    remoteMethod: null,
    companions: const <AppointmentCompanion>[],
    status: AppointmentStatus.scheduled,
    updatedAt: DateTime.utc(2026, 11),
  );
}

/// Nora's circle, on her own phone.
const ReminderCircle _circle = ReminderCircle(
  id: 'c-1',
  name: 'دائرة نورة',
  viewerId: 'nora',
  viewerIsPatient: true,
  timeZone: 'Asia/Riyadh',
);

final CalendarEventTexts _texts = CalendarEventTexts(
  dose: (String circleId, String medicine) => 'dose $medicine',
  doseNote: () => 'dose note',
  measurement: (String circleId, MeasurementKind kind) => 'read ${kind.name}',
  appointment: (String circleId, CareAppointment visit) =>
      'visit ${visit.specialty}',
  appointmentNote: (CareAppointment visit) => 'at ${visit.time}',
);

void main() {
  group('CalendarSync', () {
    late _Calendar calendar;
    late _Appointments appointments;
    late CalendarSync sync;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      calendar = _Calendar();
      appointments = _Appointments()
        ..visits[_circle.id] = <CareAppointment>[_visit()];
      sync = CalendarSync(
        MedicationsUseCase(_Medications()),
        _Measurements(),
        appointments,
        calendar: calendar,
        texts: _texts,
      );
    });

    Future<void> turnOn() async {
      await sync.sync(<ReminderCircle>[_circle]);
      await sync.setEnabled(
        _circle.id,
        CalendarSyncCategory.appointments,
        true,
      );
    }

    Future<void> turnOff() =>
        sync.setEnabled(_circle.id, CalendarSyncCategory.appointments, false);

    test(
      'an appointment is added with its words, place and reminders',
      () async {
        await turnOn();

        final _Event event = calendar.events.values.single;
        expect(event.title, 'visit diabetes');
        expect(event.note, 'at 16:30');
        expect(event.place, 'الحبيب');
        expect(event.repeats, isFalse);
        // The same as its notifications: a day before, and two hours before.
        expect(event.reminders, const <Duration>[
          Duration(days: 1),
          Duration(hours: 2),
        ]);
      },
    );

    test(
      "an event is at the patient's time, kept in the patient's zone",
      () async {
        // The patient lives in London: the visit at 16:30 is 16:30 there,
        // whatever zone this phone (the test machine) is in, and the calendar
        // keeps it in London's zone across DST.
        const ReminderCircle london = ReminderCircle(
          id: 'c-1',
          name: 'دائرة نورة',
          viewerId: 'nora',
          viewerIsPatient: true,
          timeZone: 'Europe/London',
        );
        await sync.sync(<ReminderCircle>[london]);
        await sync.setEnabled(
          london.id,
          CalendarSyncCategory.appointments,
          true,
        );

        final _Event event = calendar.events.values.single;
        final CareAppointment visit = _visit();
        expect(event.zone, 'Europe/London');
        expect(
          event.start,
          london.clock.momentOf(visit.scheduledOn, visit.time).toLocal(),
        );
      },
    );

    test(
      'the injected clock decides whether an appointment is still ahead',
      () async {
        final CareAppointment visit = _visit();
        final DateTime at = _circle.clock
            .momentOf(visit.scheduledOn, visit.time)
            .toLocal();
        final CalendarSync lateSync = CalendarSync(
          MedicationsUseCase(_Medications()),
          _Measurements(),
          appointments,
          calendar: calendar,
          texts: _texts,
          clock: () => at.add(const Duration(minutes: 1)),
        );

        await lateSync.sync(<ReminderCircle>[_circle]);
        await lateSync.setEnabled(
          _circle.id,
          CalendarSyncCategory.appointments,
          true,
        );

        expect(calendar.events, isEmpty);
      },
    );

    test('turning the switch off takes the events off the calendar', () async {
      await turnOn();
      expect(calendar.events, hasLength(1));

      await turnOff();

      expect(calendar.events, isEmpty);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calendar_sync_events'), isNull);
    });

    test(
      'with add-only access it asks once, and deletes once allowed',
      () async {
        await turnOn();
        calendar
          ..status = CalendarPermissionStatus.writeOnly
          ..answer = CalendarPermissionStatus.writeOnly;

        await turnOff();
        // Not allowed yet: the event stays, and is remembered.
        expect(calendar.asked, 1);
        expect(calendar.events, hasLength(1));
        await sync.refresh();
        expect(calendar.asked, 1);

        // Allowed in the Settings app later.
        calendar.status = CalendarPermissionStatus.granted;
        await sync.refresh();

        expect(calendar.events, isEmpty);
      },
    );

    test('an event the calendar gave another id is still found', () async {
      await turnOn();
      calendar.renumber(calendar.events.keys.single);

      await turnOff();

      expect(calendar.events, isEmpty);
    });

    test('a circle that cannot be read now keeps its events', () async {
      await turnOn();
      appointments.offline = true;

      await sync.refresh();
      expect(calendar.events, hasLength(1));

      // Turned off while offline: off the calendar all the same.
      await turnOff();
      expect(calendar.events, isEmpty);
    });

    test('an edited appointment replaces its event', () async {
      await turnOn();
      appointments.visits[_circle.id] = <CareAppointment>[
        _visit(time: '18:00'),
      ];

      await sync.refresh();

      expect(calendar.events.values.single.note, 'at 18:00');
    });

    test('an event of the older wording is replaced', () async {
      final CareAppointment visit = _visit();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'calendar_sync_selections': <String>['c-1:appointments'],
        'calendar_sync_events': jsonEncode(<String, String>{
          'appointment:a-1:${visit.scheduledOn.toIso8601String()}:16:30':
              'old-1',
        }),
      });
      calendar.events['old-1'] = (
        title: 'دائرة نورة · السكري',
        start: DateTime.now().add(const Duration(days: 3)),
        repeats: false,
        note: null,
        place: null,
        reminders: null,
        zone: null,
      );

      await sync.sync(<ReminderCircle>[_circle]);

      expect(calendar.events.keys, isNot(contains('old-1')));
      expect(calendar.events.values.single.title, 'visit diabetes');
    });

    test('before the circles are known, nothing is taken off', () async {
      await turnOn();
      final CalendarSync later = CalendarSync(
        MedicationsUseCase(_Medications()),
        _Measurements(),
        appointments,
        calendar: calendar,
        texts: _texts,
      );

      // Another switch, on a page opened before the home data loaded.
      await later.setEnabled('c-2', CalendarSyncCategory.doses, true);

      expect(calendar.events, hasLength(1));
    });

    test('signing out takes every event off', () async {
      await turnOn();

      await sync.clear();

      expect(calendar.events, isEmpty);
      expect(
        await sync.isEnabled(_circle.id, CalendarSyncCategory.appointments),
        isFalse,
      );
    });

    testWidgets('the words follow the reminders', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          // The translations load through the app's localization delegates.
          child: Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      CareVoice.update(<String, String?>{'c-noura': 'نورة', 'c-me': null});
      addTearDown(CareVoice.clear);

      expect(calendarEventTexts.dose('c-me', 'أنسولين'), 'لا ننسى الأنسولين');
      expect(
        calendarEventTexts.dose('c-noura', 'البنادول'),
        'لا ننسى البنادول لـنورة',
      );
      expect(calendarEventTexts.doseNote(), 'حان موعد الدواء');
      expect(
        calendarEventTexts.measurement('c-noura', MeasurementKind.glucose),
        'وقت القياس: سكر الدم لـنورة',
      );
      expect(
        calendarEventTexts.appointment('c-me', _visit()),
        'لا ننسى موعدك: عيادة السكري',
      );
      expect(
        calendarEventTexts.appointment('c-noura', _visit()),
        'لا ننسى موعد نورة: عيادة السكري',
      );
      expect(
        calendarEventTexts.appointmentNote(_visit()),
        'عيادة السكري · الساعة 4:30 م · الحبيب',
      );
    });

    group('a task put off', () {
      late ValueNotifier<Map<String, TaskSnooze>> snoozes;
      late CalendarSync putOff;

      setUp(() {
        appointments.visits.clear();
        snoozes = ValueNotifier<Map<String, TaskSnooze>>(
          const <String, TaskSnooze>{},
        );
        putOff = CalendarSync(
          MedicationsUseCase(_Medications()),
          _Measurements(),
          appointments,
          snoozes: snoozes,
          calendar: calendar,
          texts: _texts,
        );
      });

      TaskSnooze dose(Duration after) => TaskSnooze(
        circleId: _circle.id,
        task: SnoozedTask.dose,
        subject: 'ميتفورمين',
        at: DateTime.now().toUtc().add(after),
      );

      test('gets one event at its new time, moved when put off again, and '
          'gone once it ends', () async {
        await putOff.sync(<ReminderCircle>[_circle]);
        await putOff.setEnabled(_circle.id, CalendarSyncCategory.doses, true);

        final TaskSnooze first = dose(const Duration(minutes: 15));
        snoozes.value = <String, TaskSnooze>{'c-1|s|2026-11-9': first};
        await pumpEventQueue();

        expect(calendar.events.values.single.title, 'dose ميتفورمين');
        expect(calendar.events.values.single.start, first.at.toLocal());
        expect(calendar.events.values.single.repeats, isFalse);
        expect(calendar.events.values.single.note, 'dose note');
        expect(calendar.events.values.single.reminders, <Duration>[
          Duration.zero,
        ]);

        final TaskSnooze again = dose(const Duration(hours: 1));
        snoozes.value = <String, TaskSnooze>{'c-1|s|2026-11-9': again};
        await pumpEventQueue();
        expect(calendar.events.values.single.start, again.at.toLocal());

        // Recorded, or its time came.
        snoozes.value = const <String, TaskSnooze>{};
        await pumpEventQueue();
        expect(calendar.events, isEmpty);
      });

      test('in a category that is off, gets no event', () async {
        await putOff.sync(<ReminderCircle>[_circle]);
        await putOff.setEnabled(_circle.id, CalendarSyncCategory.doses, true);

        snoozes.value = <String, TaskSnooze>{
          'c-1|measurement|v|08:00|2026-11-9': TaskSnooze(
            circleId: _circle.id,
            task: SnoozedTask.measurement,
            subject: MeasurementKind.bp.name,
            at: DateTime.now().toUtc().add(const Duration(minutes: 15)),
          ),
        };
        await pumpEventQueue();

        expect(calendar.events, isEmpty);
      });
    });
  });
}
