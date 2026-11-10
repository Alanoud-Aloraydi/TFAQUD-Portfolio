import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';

/// What is saved on the medical file's edit page shows at once on the pages
/// open under it (the medical file page and the circle tab), without reading
/// the file from the server again.
void main() {
  group('MedicalFileSaves', () {
    late CirclesFakeRepository circles;

    // One use case for all the pages, as in the app.
    late CirclesUseCase useCase;
    late CircleOverviewCubit tab;
    late MedicalFileCubit file;
    late MedicalFileEditCubit edit;

    final MedicalFile noura = CirclesFakeRepository.nouraFile;

    /// Lets the pages hear what was saved.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() async {
      circles = CirclesFakeRepository();
      useCase = CirclesUseCase(circles);
      tab = CircleOverviewCubit(useCase, 'circle-1');
      file = MedicalFileCubit(useCase, 'circle-1');
      edit = MedicalFileEditCubit(useCase, 'circle-1');
      await tab.load();
      await file.load();
    });

    tearDown(() async {
      await tab.close();
      await file.close();
      await edit.close();
    });

    test('the edit page starts from the file it is given, without a read', () {
      final int reads = circles.medicalFileReads;

      edit.start(noura);

      expect(edit.state.status, MedicalFileEditStatus.ready);
      expect(edit.state.file, noura);
      expect(edit.state.form.bloodType, 'O+');
      expect(circles.medicalFileReads, reads);
    });

    test('a saved answer shows on the file page and the tab at once', () async {
      final int reads = circles.medicalFileReads;
      edit.start(file.state.file!);
      edit.chooseBloodType('A+');

      expect(await edit.save(), isTrue);
      await settle();

      expect(file.state.status, MedicalFileStatus.ready);
      expect(file.state.file!.profile.bloodType, 'A+');
      expect(tab.state.medicalFile!.profile.bloodType, 'A+');
      expect(circles.medicalFileReads, reads);
    });

    test(
      'a file read before the save does not bring the old answer back',
      () async {
        final Completer<Result<MedicalFile, Failure>> slow =
            Completer<Result<MedicalFile, Failure>>();
        circles.queuedFileReads.add(slow.future);
        final Future<void> reading = file.load();
        edit.start(noura);
        edit.chooseBloodType('A+');

        await edit.save();
        await settle();
        slow.complete(Success<MedicalFile, Failure>(noura));
        await reading;

        expect(file.state.file!.profile.bloodType, 'A+');
      },
    );

    test('the tab keeps a save made while it was still reading', () async {
      final CircleOverviewCubit opening = CircleOverviewCubit(
        useCase,
        'circle-1',
      );
      addTearDown(opening.close);
      final Completer<Result<MedicalFile, Failure>> slow =
          Completer<Result<MedicalFile, Failure>>();
      circles.queuedFileReads.add(slow.future);
      final Future<void> reading = opening.load();
      edit.start(noura);
      edit.chooseBloodType('B-');

      await edit.save();
      await settle();
      slow.complete(Success<MedicalFile, Failure>(noura));
      await reading;

      expect(opening.state.status, CircleOverviewStatus.ready);
      expect(opening.state.medicalFile!.profile.bloodType, 'B-');
    });

    test(
      'a new city also reads the circle again for the line under its name',
      () async {
        final int circleReads = circles.circleOverviewReads;
        edit.start(noura);
        edit.cityChanged('الرياض');

        expect(await edit.save(), isTrue);
        await settle();

        expect(tab.state.medicalFile!.patient.city, 'الرياض');
        expect(circles.circleOverviewReads, circleReads + 1);
      },
    );

    test('a new answer alone does not read the circle again', () async {
      final int circleReads = circles.circleOverviewReads;
      edit.start(noura);
      edit.chooseBloodType('A+');

      await edit.save();
      await settle();

      expect(circles.circleOverviewReads, circleReads);
    });

    test('a contact saved on the file page reaches the tab', () async {
      file.startAdd();
      file.relationChosen('wife');
      file.nameChanged('سلمى');
      file.phoneChanged('555555555');

      expect(await file.saveContact(), isTrue);
      await settle();

      final List<EmergencyContact> contacts = tab.state.medicalFile!.contacts;
      expect(contacts, hasLength(noura.contacts.length + 1));
      expect(contacts.last.name, 'سلمى');
    });

    test('a save in another circle changes nothing here', () async {
      final MedicalFileEditCubit other = MedicalFileEditCubit(
        useCase,
        'circle-2',
      );
      addTearDown(other.close);
      other.start(noura);
      other.chooseBloodType('AB+');

      await other.save();
      await settle();

      expect(file.state.file!.profile.bloodType, 'O+');
      expect(tab.state.medicalFile!.profile.bloodType, 'O+');
    });
  });
}
