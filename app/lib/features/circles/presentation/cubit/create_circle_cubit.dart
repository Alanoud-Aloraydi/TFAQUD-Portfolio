import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

class CreateCircleCubit extends Cubit<CreateCircleState> {
  /// [request] is the request the patient agreed to, and is needed for the
  /// [CircleFlow.approved] flow only. Its circle name is the name of the circle.
  CreateCircleCubit(
    this._circles,
    this._home, {
    required this.flow,
    this.request,
  }) : super(CreateCircleState(circleName: request?.circleName ?? ''));

  final CirclesUseCase _circles;
  final HomeUseCase _home;

  /// Which circle is created: your own, one for a patient without the app, or
  /// the one a patient agreed to.
  final CircleFlow flow;

  /// The request of the [CircleFlow.approved] flow.
  final ReceivedCircleRequest? request;

  /// The longest first name or last name of a patient the API accepts.
  static const int maxNameLength = 50;

  /// The longest typed circle name. The API accepts 60; a short name is what
  /// fits in the row of circles at the top of the screen.
  static const int maxCustomNameLength = 30;

  // ---- account name ----------------------------------------------------

  /// Loads the account for the read-only "Name" field and to learn at once
  /// whether the account already has a circle of its own care. The pages work
  /// without it, so a failure only shows a message and a retry link; the
  /// server still refuses a second circle at the last step.
  Future<void> loadAccount() async {
    emit(state.copyWith(accountLoad: AccountLoad.loading));
    final result = await _circles.getAccount();
    if (isClosed) return;
    result.when(
      (account) {
        emit(state.copyWith(account: account, accountLoad: AccountLoad.loaded));
        // The home screen may not show that circle yet; it loads again.
        if (account.hasOwnCircle) _home.notifyCirclesChanged();
      },
      (failure) => emit(
        state.copyWith(
          accountLoad: AccountLoad.failed,
          sessionEnded: _ended(failure),
        ),
      ),
    );
  }

  // ---- step 1: basic details -------------------------------------------

  void choosePreset(NamePreset preset) {
    emit(state.copyWith(namePreset: preset, clearError: true));
  }

  void customNameChanged(String value) {
    emit(state.copyWith(customName: value, clearError: true));
  }

  void birthDateChanged(DateTime value) {
    emit(state.copyWith(birthDate: value, clearError: true));
  }

  void cityChanged(String value) {
    emit(state.copyWith(city: value, clearError: true));
  }

  /// Checks the first step. [presetName] is the text of the chosen chip, which
  /// the page translates. Returns true when the page may go to the next step.
  bool continueFromBasics({required String presetName}) {
    if (state.alreadyHasCircle) return false;
    final String name = state.namePreset == NamePreset.other
        ? state.customName.trim()
        : presetName;
    if (name.isEmpty || state.birthDate == null || state.city == null) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(state.copyWith(circleName: name, showErrors: false));
    return true;
  }

  // ---- step 1 for a patient without the app ------------------------------

  void patientFirstNameChanged(String value) {
    emit(state.copyWith(patientFirstName: value, clearError: true));
  }

  void patientLastNameChanged(String value) {
    emit(state.copyWith(patientLastName: value, clearError: true));
  }

  void chooseLabel(CircleLabel label) {
    emit(state.copyWith(label: label, clearError: true));
  }

  void customLabelChanged(String value) {
    emit(state.copyWith(customLabel: value, clearError: true));
  }

  /// Checks the first step of a circle for a patient without the app.
  /// [labelName] is the text of the chosen chip, which the page translates. The
  /// circle is named with the label and the first name of the patient. Returns
  /// true when the page may go to the next step.
  bool continueFromPatientBasics({required String labelName}) {
    final String label = state.label == CircleLabel.other
        ? state.customLabel.trim()
        : labelName;
    if (label.isEmpty ||
        !state.patientNamesComplete ||
        state.birthDate == null ||
        state.city == null) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(
      state.copyWith(
        circleName: CircleNames.compose(label, state.patientFirstName),
        showErrors: false,
      ),
    );
    return true;
  }

  // ---- step 1 for a patient who agreed to a request -----------------------

  /// Checks the first step of a circle the patient agreed to: only the birth
  /// date and the city are typed. Returns true when the page may go to the next
  /// step.
  bool continueFromApprovedBasics() {
    if (state.alreadyHasCircle) return false;
    if (state.circleName.isEmpty ||
        state.birthDate == null ||
        state.city == null) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(state.copyWith(showErrors: false));
    return true;
  }

  // ---- step 2: health condition ----------------------------------------

  /// Picks a blood type; a second tap on the same one clears it.
  void chooseBloodType(String code) {
    if (state.bloodType == code) {
      emit(state.copyWith(clearBloodType: true));
    } else {
      emit(state.copyWith(bloodType: code));
    }
  }

  /// "None" stands alone: it clears the other choices, and any other choice
  /// clears it.
  void toggleCondition(String code) {
    final Set<String> next = _toggled(state.conditions, code);
    emit(
      state.copyWith(
        conditions: next,
        conditionOther: next.contains(MedicalOptions.other)
            ? state.conditionOther
            : '',
        clearError: true,
      ),
    );
  }

  void conditionOtherChanged(String value) {
    emit(state.copyWith(conditionOther: value, clearError: true));
  }

  /// Checks the second step. Returns true when the page may go on.
  bool continueFromHealth() {
    if (!state.conditionsValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    emit(state.copyWith(showErrors: false));
    return true;
  }

  /// Drops the answers of the second step.
  void skipHealth() {
    emit(
      state.copyWith(
        clearBloodType: true,
        conditions: const <String>{},
        conditionOther: '',
        showErrors: false,
      ),
    );
  }

  // ---- step 3: allergies -----------------------------------------------

  /// "No allergies" stands alone: it clears the lists, and any item clears it.
  void toggleNoAllergies() {
    if (state.noAllergies) {
      emit(state.copyWith(noAllergies: false));
    } else {
      emit(
        state.copyWith(
          noAllergies: true,
          medication: const <String>{},
          medicationOther: '',
          food: const <String>{},
          foodOther: '',
          clearError: true,
        ),
      );
    }
  }

  void toggleMedication(String code) {
    final Set<String> next = {...state.medication};
    if (!next.add(code)) next.remove(code);
    emit(
      state.copyWith(
        medication: next,
        medicationOther: next.contains(MedicalOptions.other)
            ? state.medicationOther
            : '',
        noAllergies: false,
        clearError: true,
      ),
    );
  }

  void toggleFood(String code) {
    final Set<String> next = {...state.food};
    if (!next.add(code)) next.remove(code);
    emit(
      state.copyWith(
        food: next,
        foodOther: next.contains(MedicalOptions.other) ? state.foodOther : '',
        noAllergies: false,
        clearError: true,
      ),
    );
  }

  void medicationOtherChanged(String value) {
    emit(state.copyWith(medicationOther: value, clearError: true));
  }

  void foodOtherChanged(String value) {
    emit(state.copyWith(foodOther: value, clearError: true));
  }

  // ---- create ----------------------------------------------------------

  /// Creates the circle of the [flow]. [skipAllergies] drops the answers of the
  /// third step first. Returns true when the circle was created, so the page can
  /// leave.
  Future<bool> create({bool skipAllergies = false}) async {
    if (state.status == CreateStatus.saving) return false;
    if (state.alreadyHasCircle) {
      emit(state.copyWith(errorKey: 'circles.already_has_circle'));
      return false;
    }
    if (skipAllergies) {
      emit(
        state.copyWith(
          noAllergies: false,
          medication: const <String>{},
          medicationOther: '',
          food: const <String>{},
          foodOther: '',
        ),
      );
    }
    if (!state.allergiesValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    final DateTime? birthDate = state.birthDate;
    final String? city = state.city;
    final bool namesMissing =
        flow == CircleFlow.patient && !state.patientNamesComplete;
    final bool requestMissing = flow == CircleFlow.approved && request == null;
    if (!state.basicsComplete ||
        namesMissing ||
        requestMissing ||
        birthDate == null ||
        city == null) {
      emit(state.copyWith(errorKey: 'error.invalid_data'));
      return false;
    }
    emit(
      state.copyWith(
        status: CreateStatus.saving,
        clearError: true,
        showErrors: false,
      ),
    );
    final Result<CareCircleSummary, Failure> result;
    switch (flow) {
      case CircleFlow.self:
        result = await _circles.createSelfCircle(
          NewSelfCircle(
            name: state.circleName,
            birthDate: birthDate,
            city: city,
            medicalProfile: _medicalProfile(),
          ),
        );
      case CircleFlow.patient:
        result = await _circles.createPatientCircle(
          NewPatientCircle(
            name: state.circleName,
            patientFirstName: state.patientFirstName.trim(),
            patientLastName: state.patientLastName.trim(),
            birthDate: birthDate,
            city: city,
            medicalProfile: _medicalProfile(),
          ),
        );
      case CircleFlow.approved:
        result = await _circles.completeRequest(
          request!.id,
          CompleteCircleRequest(
            birthDate: birthDate,
            city: city,
            medicalProfile: _medicalProfile(),
          ),
        );
    }
    if (isClosed) return false;
    return result.when(
      (circle) {
        // Every open home screen loads the circles again and selects this one.
        _home.notifyCirclesChanged(select: circle.id);
        emit(state.copyWith(status: CreateStatus.created));
        return true;
      },
      (failure) {
        // The first try may have been saved with its answer lost. Loading the
        // circles again shows it.
        if (failure is AlreadyHasCircleFailure) _home.notifyCirclesChanged();
        emit(
          state.copyWith(
            status: CreateStatus.idle,
            errorKey: failure.messageKey,
            sessionEnded: _ended(failure),
          ),
        );
        return false;
      },
    );
  }

  // ---- helpers ---------------------------------------------------------

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;

  Set<String> _toggled(Set<String> chosen, String code) {
    final Set<String> next = {...chosen};
    if (code == MedicalOptions.none) {
      if (next.contains(code)) {
        next.remove(code);
      } else {
        next
          ..clear()
          ..add(code);
      }
      return next;
    }
    next.remove(MedicalOptions.none);
    if (!next.add(code)) next.remove(code);
    return next;
  }

  /// The parts the user answered, or null when the user answered none.
  MedicalProfileDraft? _medicalProfile() {
    final MedicalProfileDraft draft = MedicalProfileDraft(
      bloodType: state.bloodType,
      conditions: _conditions(),
      allergies: _allergies(),
    );
    return draft.isEmpty ? null : draft;
  }

  ConditionsDraft? _conditions() {
    final Set<String> chosen = state.conditions;
    if (chosen.isEmpty) return null;
    if (chosen.contains(MedicalOptions.none)) {
      return const ConditionsDraft.none();
    }
    final List<String> codes = _inOrder(chosen, <String>[
      ...MedicalOptions.conditions,
      MedicalOptions.other,
    ]);
    return ConditionsDraft.listed(
      codes: codes,
      other: codes.contains(MedicalOptions.other)
          ? state.conditionOther.trim()
          : null,
    );
  }

  AllergiesDraft? _allergies() {
    if (state.noAllergies) return const AllergiesDraft.none();
    if (state.medication.isEmpty && state.food.isEmpty) return null;
    final List<String> medication = _inOrder(state.medication, <String>[
      ...MedicalOptions.medications,
      MedicalOptions.other,
    ]);
    final List<String> food = _inOrder(state.food, <String>[
      ...MedicalOptions.foods,
      MedicalOptions.other,
    ]);
    return AllergiesDraft.listed(
      medication: medication,
      otherMedication: medication.contains(MedicalOptions.other)
          ? state.medicationOther.trim()
          : null,
      food: food,
      otherFood: food.contains(MedicalOptions.other)
          ? state.foodOther.trim()
          : null,
    );
  }

  /// The chosen codes in the order of the design.
  List<String> _inOrder(Set<String> chosen, List<String> order) {
    return <String>[
      for (final String code in order)
        if (chosen.contains(code)) code,
    ];
  }
}
