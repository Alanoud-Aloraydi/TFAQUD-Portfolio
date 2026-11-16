import 'package:app/features/circles/presentation/cubit/circle_flow.dart';

/// Loading of the signed-in account, which gives the name shown on the
/// approved page, whether the account already has a circle of its own care
/// and the birth date and city onboarding saved.
enum AccountLoad {
  loading,
  loaded,
  failed,

  /// The [CircleFlow.patient] flow reads no account: the patient is someone
  /// else.
  notNeeded,
}
