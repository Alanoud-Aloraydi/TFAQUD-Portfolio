import 'package:app/core/navigation/routes/appointment_routes.dart';
import 'package:app/core/navigation/routes/measurement_routes.dart';
import 'package:app/core/navigation/routes/medication_routes.dart';
import 'package:go_router/go_router.dart';

/// The pages of a circle's medicines, measurements and appointments, opened
/// from the home tabs. Each one loads what it shows for the circle in the
/// address.
List<RouteBase> careRoutes() => <RouteBase>[
  medicationNewRoute(),
  ...measurementRoutes(),
  ...appointmentRoutes(),
  ...medicationPlanRoutes(),
];
