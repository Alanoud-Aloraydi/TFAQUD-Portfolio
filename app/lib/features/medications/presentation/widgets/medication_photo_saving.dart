import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/network/medication_endpoints.dart';

/// Saving the medicine's photo, once the plan it belongs to has an id. The
/// form closes on «تم» whether a photo was picked or not; only a photo that
/// could not be stored keeps it open, with its own message.
extension MedicationPhotoSaving on MedicationFormState {
  Future<void> savePhoto(String planId) async {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final path = MedicationEndpoints.medicationPhoto(widget.circleId, planId);
    try {
      if (photoDirty) {
        if (photoRemoved) {
          await repository.remove(path);
        } else if (photo != null) {
          await repository.save(path, photo!);
        }
      }
    } catch (_) {
      if (mounted) update(() => errorKey = 'photos.save_failed');
      return;
    }
    if (!mounted) return;
    dirty = false;
    AppToast.show(context, 'toast.medication_saved');
    context.pop(true);
  }
}
