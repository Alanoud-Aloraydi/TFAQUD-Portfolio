import 'dart:async';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/measurement_endpoints.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';

/// The requests about the plans themselves: reading them, adding one,
/// changing one and stopping one. Each accepted change is announced on
/// [planChanges].
mixin MeasurementPlanRequests {
  DioClient get client;

  /// Where the circle of an accepted plan change is announced.
  StreamController<String> get planChanges;

  /// Every plan of [circleId], stopped ones too.
  Future<List<MeasurementPlan>> plans(String circleId) async {
    final response = await client.get(
      MeasurementEndpoints.measurementPlans(circleId),
    );
    final values =
        (response.data as Map<String, dynamic>)['measurement_plans']
            as List<dynamic>;
    return knownMeasurementItems(values, MeasurementPlan.fromJson);
  }

  /// Adds a plan from [draft]; the server refuses a second active plan of
  /// one kind and a start before the patient's today.
  Future<MeasurementPlan> createPlan(
    String circleId,
    MeasurementPlanDraft draft,
  ) async {
    final response = await client.post(
      MeasurementEndpoints.measurementPlans(circleId),
      data: draft.toJson(),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  /// Changes [plan] from [draft]'s start on; readings already taken keep
  /// the version they were taken under.
  Future<MeasurementPlan> revisePlan(
    String circleId,
    MeasurementPlan plan,
    MeasurementPlanDraft draft,
  ) async {
    final response = await client.put(
      MeasurementEndpoints.measurementPlan(circleId, plan.id),
      // The latest version: a change waiting for later is the one changed.
      data: draft.toJson(
        expectedVersion: (plan.pendingVersion ?? plan.version).number,
      ),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  /// Stops [planId]: no task after now.
  Future<MeasurementPlan> stopPlan(String circleId, String planId) async {
    final response = await client.post(
      MeasurementEndpoints.stopMeasurementPlan(circleId, planId),
    );
    planChanges.add(circleId);
    return _plan(response.data);
  }

  static MeasurementPlan _plan(Object? data) => MeasurementPlan.fromJson(
    (data as Map<String, dynamic>)['measurement_plan'] as Map<String, dynamic>,
  );
}
