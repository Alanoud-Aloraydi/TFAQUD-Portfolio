import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_questions.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
export 'package:app/features/circles/presentation/cubit/create_circle_questions.dart';

/// State of the page that creates a circle: the circle's name, or the
/// patient's names, and the patient's birth date and city.
class CreateCircleState extends Equatable {
  const CreateCircleState({
    this.account,
    this.accountLoad = AccountLoad.loading,
    this.namePreset = NamePreset.care,
    this.customName = '',
    this.patientFirstName = '',
    this.patientLastName = '',
    this.birthDate,
    this.city,
    this.showErrors = false,
    this.status = CreateStatus.idle,
    this.errorKey,
    this.sessionEnded = false,
    this.switchToSimplified = false,
  });

  final AccountSummary? account;
  final AccountLoad accountLoad;

  /// The chosen name chip and, for [NamePreset.other], the typed name.
  final NamePreset namePreset;
  final String customName;

  /// The patient's names, typed for a patient without the app.
  final String patientFirstName;
  final String patientLastName;

  /// The birth date and city typed on the page; unused when the account
  /// holds its own (`ownBasicsSaved`).
  final DateTime? birthDate;
  final String? city;

  /// True after a tap on the create button with a missing answer.
  final bool showErrors;

  final CreateStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// True right after `CircleFlow.approved` commits the account to
  /// simplified mode: the page goes to the simplified home instead of the
  /// detailed circle tab.
  final bool switchToSimplified;

  @override
  List<Object?> get props => createCircleProps(this);
}

/// The progress of the create call.
enum CreateStatus { idle, saving, created }

/// The circle name chips of the person's own circle: the one for their own
/// care, or the one they agreed to. Only they see this name. [other] lets
/// them type a name.
enum NamePreset { care, health, circle, other }

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
