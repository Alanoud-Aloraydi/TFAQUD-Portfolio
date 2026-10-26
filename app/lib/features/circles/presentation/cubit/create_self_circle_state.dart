import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:equatable/equatable.dart';

/// The circle name chips of the first step. [other] lets the user type a name.
enum NamePreset { care, health, circle, other }

/// Loading of the account names shown in the read-only "Name" field.
enum AccountLoad { loading, loaded, failed }

enum CreateStatus { idle, saving, created }

/// State of the three pages that create the circle of the signed-in person:
/// basic details, health condition, allergies. One cubit keeps the answers of
/// all three, so going back never loses them.
class CreateSelfCircleState extends Equatable {
  const CreateSelfCircleState({
    this.account,
    this.accountLoad = AccountLoad.loading,
    this.namePreset = NamePreset.care,
    this.customName = '',
    this.circleName = '',
    this.birthDate,
    this.city,
    this.bloodType,
    this.conditions = const <String>{},
    this.conditionOther = '',
    this.noAllergies = false,
    this.medication = const <String>{},
    this.medicationOther = '',
    this.food = const <String>{},
    this.foodOther = '',
    this.showErrors = false,
    this.status = CreateStatus.idle,
    this.errorKey,
    this.sessionEnded = false,
  });

  final AccountSummary? account;
  final AccountLoad accountLoad;

  // Step 1: basic details.
  final NamePreset namePreset;
  final String customName;

  /// The name the circle gets. Set when the first step is complete.
  final String circleName;
  final DateTime? birthDate;
  final String? city;

  // Step 2: health condition.
  final String? bloodType;

  /// Codes of the chosen conditions, including "none" and "other".
  final Set<String> conditions;
  final String conditionOther;

  // Step 3: allergies.
  final bool noAllergies;
  final Set<String> medication;
  final String medicationOther;
  final Set<String> food;
  final String foodOther;

  /// True after a tap on a button with a missing answer.
  final bool showErrors;

  final CreateStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  String? get fullName => account?.fullName;

  /// The account already has a circle for its own care. Nothing can be created,
  /// so the first page says so before anything is filled in.
  bool get alreadyHasCircle => account?.hasOwnCircle ?? false;

  /// The first step is complete and the circle name is set.
  bool get basicsComplete =>
      circleName.isNotEmpty && birthDate != null && city != null;

  /// "Other" needs its text, here and in the two lists of step 3.
  bool get conditionsValid =>
      !conditions.contains(MedicalOptions.other) ||
      conditionOther.trim().isNotEmpty;

  bool get allergiesValid =>
      (!medication.contains(MedicalOptions.other) ||
          medicationOther.trim().isNotEmpty) &&
      (!food.contains(MedicalOptions.other) || foodOther.trim().isNotEmpty);

  CreateSelfCircleState copyWith({
    AccountSummary? account,
    AccountLoad? accountLoad,
    NamePreset? namePreset,
    String? customName,
    String? circleName,
    DateTime? birthDate,
    String? city,
    String? bloodType,
    bool clearBloodType = false,
    Set<String>? conditions,
    String? conditionOther,
    bool? noAllergies,
    Set<String>? medication,
    String? medicationOther,
    Set<String>? food,
    String? foodOther,
    bool? showErrors,
    CreateStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
  }) {
    return CreateSelfCircleState(
      account: account ?? this.account,
      accountLoad: accountLoad ?? this.accountLoad,
      namePreset: namePreset ?? this.namePreset,
      customName: customName ?? this.customName,
      circleName: circleName ?? this.circleName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      bloodType: clearBloodType ? null : (bloodType ?? this.bloodType),
      conditions: conditions ?? this.conditions,
      conditionOther: conditionOther ?? this.conditionOther,
      noAllergies: noAllergies ?? this.noAllergies,
      medication: medication ?? this.medication,
      medicationOther: medicationOther ?? this.medicationOther,
      food: food ?? this.food,
      foodOther: foodOther ?? this.foodOther,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [
    account,
    accountLoad,
    namePreset,
    customName,
    circleName,
    birthDate,
    city,
    bloodType,
    conditions,
    conditionOther,
    noAllergies,
    medication,
    medicationOther,
    food,
    foodOther,
    showErrors,
    status,
    errorKey,
    sessionEnded,
  ];
}
