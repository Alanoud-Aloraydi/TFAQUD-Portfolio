import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicalForm.fromProfile', () {
    test('a file nobody answered has no chosen chip', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(),
      );

      expect(form, const MedicalForm());
    });

    test('shows the saved blood type', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(bloodType: 'AB-'),
      );

      expect(form.bloodType, 'AB-');
    });

    test('"no chronic conditions" chooses only "none"', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(conditions: ConditionsDraft.none()),
      );

      expect(form.conditions, <String>{MedicalOptions.none});
    });

    test('listed conditions keep their codes and the typed "other"', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(
          conditions: ConditionsDraft.listed(
            codes: <String>['diabetes', 'other'],
            other: 'نقرس',
          ),
        ),
      );

      expect(form.conditions, <String>{'diabetes', 'other'});
      expect(form.conditionOther, 'نقرس');
    });

    test('"no allergies" is chosen with both lists empty', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(allergies: AllergiesDraft.none()),
      );

      expect(form.noAllergies, isTrue);
      expect(form.medication, isEmpty);
      expect(form.food, isEmpty);
    });

    test('listed allergies keep both lists and their typed "other"', () {
      final MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(
          allergies: AllergiesDraft.listed(
            medication: <String>['penicillin', 'other'],
            otherMedication: 'يود',
            food: <String>['milk'],
          ),
        ),
      );

      expect(form.noAllergies, isFalse);
      expect(form.medication, <String>{'penicillin', 'other'});
      expect(form.medicationOther, 'يود');
      expect(form.food, <String>{'milk'});
      expect(form.foodOther, '');
    });
  });

  group('MedicalForm.toProfile', () {
    test('a form with nothing chosen gives an empty profile', () {
      expect(const MedicalForm().toProfile().isEmpty, isTrue);
    });

    test('what the server sends comes back unchanged', () {
      const List<MedicalProfileDraft> profiles = <MedicalProfileDraft>[
        MedicalProfileDraft(bloodType: 'O+'),
        MedicalProfileDraft(conditions: ConditionsDraft.none()),
        MedicalProfileDraft(allergies: AllergiesDraft.none()),
        MedicalProfileDraft(
          bloodType: 'B-',
          conditions: ConditionsDraft.listed(
            codes: <String>['diabetes', 'heart', 'other'],
            other: 'نقرس',
          ),
          allergies: AllergiesDraft.listed(
            medication: <String>['penicillin', 'other'],
            otherMedication: 'يود',
            food: <String>['milk', 'peanuts'],
          ),
        ),
      ];

      for (final MedicalProfileDraft profile in profiles) {
        expect(MedicalForm.fromProfile(profile).toProfile(), profile);
      }
    });

    test('the chosen codes are in the order of the design', () {
      MedicalForm form = const MedicalForm();
      form = form.toggleCondition('heart');
      form = form.toggleCondition('diabetes');
      form = form.toggleMedication('sulfa');
      form = form.toggleMedication('penicillin');
      form = form.toggleFood('wheat');
      form = form.toggleFood('milk');

      final MedicalProfileDraft profile = form.toProfile();

      expect(profile.conditions?.codes, <String>['diabetes', 'heart']);
      expect(profile.allergies?.medication, <String>['penicillin', 'sulfa']);
      expect(profile.allergies?.food, <String>['milk', 'wheat']);
    });

    test('the typed text of "other" is trimmed', () {
      MedicalForm form = const MedicalForm();
      form = form.toggleCondition(MedicalOptions.other);
      form = form.withConditionOther('  نقرس  ');

      expect(form.toProfile().conditions?.other, 'نقرس');
    });

    test('a choice that was cleared goes back to unknown', () {
      MedicalForm form = MedicalForm.fromProfile(
        const MedicalProfileDraft(
          bloodType: 'O+',
          conditions: ConditionsDraft.none(),
          allergies: AllergiesDraft.none(),
        ),
      );
      form = form.chooseBloodType('O+');
      form = form.toggleCondition(MedicalOptions.none);
      form = form.toggleNoAllergies();

      expect(form.toProfile().isEmpty, isTrue);
    });
  });

  group('MedicalForm choices', () {
    test('a second tap on the blood type clears it', () {
      final MedicalForm once = const MedicalForm().chooseBloodType('A+');
      final MedicalForm twice = once.chooseBloodType('A+');

      expect(once.bloodType, 'A+');
      expect(twice.bloodType, isNull);
    });

    test('another blood type replaces the first', () {
      final MedicalForm form = const MedicalForm()
          .chooseBloodType('A+')
          .chooseBloodType('B+');

      expect(form.bloodType, 'B+');
    });

    test('"none" clears the conditions and any condition clears "none"', () {
      MedicalForm form = const MedicalForm()
          .toggleCondition('diabetes')
          .toggleCondition('heart');
      form = form.toggleCondition(MedicalOptions.none);
      expect(form.conditions, <String>{MedicalOptions.none});

      form = form.toggleCondition('asthma');
      expect(form.conditions, <String>{'asthma'});
    });

    test('a second tap on "none" clears it', () {
      final MedicalForm form = const MedicalForm()
          .toggleCondition(MedicalOptions.none)
          .toggleCondition(MedicalOptions.none);

      expect(form.conditions, isEmpty);
    });

    test('the typed condition is forgotten when "other" is cleared', () {
      MedicalForm form = const MedicalForm()
          .toggleCondition(MedicalOptions.other)
          .withConditionOther('نقرس');
      form = form.toggleCondition(MedicalOptions.other);

      expect(form.conditionOther, '');
      expect(form.conditions, isEmpty);
    });

    test('"no allergies" clears both lists and any item clears it', () {
      MedicalForm form = const MedicalForm()
          .toggleMedication('penicillin')
          .toggleFood('milk');
      form = form.toggleNoAllergies();
      expect(form.noAllergies, isTrue);
      expect(form.medication, isEmpty);
      expect(form.food, isEmpty);

      form = form.toggleFood('eggs');
      expect(form.noAllergies, isFalse);
      expect(form.food, <String>{'eggs'});
    });

    test('a second tap on "no allergies" clears it', () {
      final MedicalForm form = const MedicalForm()
          .toggleNoAllergies()
          .toggleNoAllergies();

      expect(form.noAllergies, isFalse);
    });

    test('the typed medicine and food are forgotten with "other"', () {
      MedicalForm form = const MedicalForm()
          .toggleMedication(MedicalOptions.other)
          .withMedicationOther('يود')
          .toggleFood(MedicalOptions.other)
          .withFoodOther('كيوي');
      form = form
          .toggleMedication(MedicalOptions.other)
          .toggleFood(MedicalOptions.other);

      expect(form.medicationOther, '');
      expect(form.foodOther, '');
    });
  });

  group('MedicalForm rules', () {
    test('"other" among the conditions needs its text', () {
      final MedicalForm chosen = const MedicalForm().toggleCondition(
        MedicalOptions.other,
      );

      expect(chosen.conditionsValid, isFalse);
      expect(chosen.withConditionOther('   ').conditionsValid, isFalse);
      expect(chosen.withConditionOther('نقرس').conditionsValid, isTrue);
    });

    test('conditions without "other" are valid', () {
      expect(const MedicalForm().conditionsValid, isTrue);
      expect(
        const MedicalForm().toggleCondition('diabetes').conditionsValid,
        isTrue,
      );
    });

    test('"other" among the allergies needs its text, in each list', () {
      final MedicalForm medicine = const MedicalForm().toggleMedication(
        MedicalOptions.other,
      );
      final MedicalForm food = const MedicalForm().toggleFood(
        MedicalOptions.other,
      );

      expect(medicine.allergiesValid, isFalse);
      expect(medicine.withMedicationOther('يود').allergiesValid, isTrue);
      expect(food.allergiesValid, isFalse);
      expect(food.withFoodOther('كيوي').allergiesValid, isTrue);
    });

    test('allergies nobody chose are valid', () {
      expect(const MedicalForm().allergiesValid, isTrue);
      expect(const MedicalForm().toggleNoAllergies().allergiesValid, isTrue);
    });
  });
}
