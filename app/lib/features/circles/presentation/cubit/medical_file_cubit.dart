import 'dart:async';

import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_fields.dart';
import 'package:app/features/circles/presentation/cubit/contact_kept.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/cubit/contact_saving.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_loading.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medical file page (CIRCLE-05): reads the file of one circle and adds,
/// changes and removes its emergency contacts. The health answers, the birth
/// date and the city are changed on the edit page.
class MedicalFileCubit extends Cubit<MedicalFileState>
    with
        MedicalFileScope,
        MedicalFileLoading,
        ContactFormOpening,
        ContactFormFields,
        ContactKept,
        ContactSaving,
        ContactDeleting {
  MedicalFileCubit(this.circles, this.circleId)
    : super(const MedicalFileState()) {
    _saves = circles.medicalFileSaves(circleId).listen(takeSaved);
  }

  @override
  final CirclesUseCase circles;

  @override
  final String circleId;

  /// The files saved on the edit page while this page is open under it.
  late final StreamSubscription<MedicalFile> _saves;

  @override
  Future<void> close() async {
    await _saves.cancel();
    return super.close();
  }
}
