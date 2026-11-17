import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_answers.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_basics.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_loading.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_saving.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the birth date, the
/// city and its time zone, the names of a patient without an account, the
/// blood type, the chronic
/// conditions and the allergies. Each part is saved with the call of its own,
/// and only the parts that changed are sent.
class MedicalFileEditCubit extends Cubit<MedicalFileEditState>
    with
        MedicalFileEditScope,
        MedicalFileEditLoading,
        MedicalFileEditBasics,
        MedicalFileEditAnswers,
        MedicalFileEditSaving {
  MedicalFileEditCubit(this.circles, this.circleId)
    : super(const MedicalFileEditState());

  @override
  final CirclesUseCase circles;

  @override
  final String circleId;
}
