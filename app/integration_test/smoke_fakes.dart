import 'dart:typed_data';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/prayer_times/data/prayer_day_model.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

// The offline repositories of the device smoke flow (smoke_test.dart): a
// signed-in phone whose server answers with empty plans, so the app opens
// on its tabs without a network.

/// A phone that is signed in; the router reads the tokens first.
class SmokeSignedInTokens implements TokenStorage {
  @override
  int get revision => 0;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> saveAccessToken(
    String accessToken, {
    int? expectedRevision,
  }) async {}

  @override
  Future<String?> readAccessToken() async => 'smoke-access-token';

  @override
  Future<String?> readRefreshToken() async => 'smoke-refresh-token';

  @override
  Future<void> clear({int? expectedRevision}) async {}
}

/// Answers the account page's sign-in calls without a server.
class SmokeAuthRepository implements AuthRepositoryDomain {
  @override
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async => const Success(
    CodeRequest(verificationId: 'verification-id', resendAfterSeconds: 30),
  );

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async => const Success(SignInResult(needsProfile: false));

  @override
  Future<Result<bool, Failure>> signOut() async => const Success(true);

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async =>
      const Success(SignInResult(needsProfile: false));
}

/// Saves nothing; the smoke flow never edits the account.
class SmokeProfileRepository implements ProfileRepositoryDomain {
  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async => const Success(null);
}

/// No medication plans and no doses.
class SmokeMedicationsRepository extends Fake
    implements MedicationsRepositoryDomain {
  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) async => const Success(<MedicationPlan>[]);

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async => const Success(<DoseOccurrence>[]);
}

/// No measurement plans and no readings.
class SmokeMeasurementsRepository extends Fake
    implements MeasurementRepository {
  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Stream<String> get recorded => const Stream<String>.empty();

  @override
  Future<List<MeasurementReading>> allReadings(String circleId) async =>
      const <MeasurementReading>[];

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async =>
      const <MeasurementPlan>[];

  @override
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const <MeasurementOccurrence>[];

  @override
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const <MeasurementReading>[];
}

/// No appointments.
class SmokeAppointmentsRepository extends Fake
    implements AppointmentRepository {
  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async =>
      const <CareAppointment>[];
}

/// The phone's calendar stays untouched: the setting is off.
class SmokeCalendarSync extends Fake implements CalendarSync {
  @override
  Future<bool> isEnabled(
    String circleId,
    CalendarSyncCategory category,
  ) async => false;

  @override
  Future<void> setEnabled(
    String circleId,
    CalendarSyncCategory category,
    bool value,
  ) async {}

  @override
  Future<void> sync(List<ReminderCircle> circles) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> clear() async {}
}

/// Fixed prayer times, without the server.
class SmokePrayerTimes extends Fake implements PrayerTimesRemoteDataSource {
  @override
  Future<PrayerDayModel> getToday(String circleId) async => PrayerDayModel(
    PrayerDay(
      date: DateUtils.dateOnly(DateTime.now()),
      city: 'الرياض',
      times: const <Prayer, String>{
        Prayer.fajr: '05:00',
        Prayer.dhuhr: '12:00',
        Prayer.asr: '15:00',
        Prayer.maghrib: '18:00',
        Prayer.isha: '19:30',
      },
    ),
  );
}

/// No private photos.
class SmokePhotoRepository implements PrivatePhotoRepository {
  final ValueNotifier<int> _changes = ValueNotifier<int>(0);

  @override
  Listenable get changes => _changes;

  @override
  Future<Uint8List?> load(String path) async => null;

  @override
  Future<void> save(String path, Uint8List bytes) async {}

  @override
  Future<void> remove(String path) async {}

  @override
  Future<void> chooseAvatar(String path, String code) async {}

  @override
  void invalidateCache() {}

  @override
  void clear() {}

  @override
  void dispose() => _changes.dispose();
}
