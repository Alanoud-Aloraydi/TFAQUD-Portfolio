import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Who sees the photo: the account's own photo ([frontCamera]) or a
/// patient's.
class PhotoVisibilityNote extends StatelessWidget {
  const PhotoVisibilityNote({super.key, required this.frontCamera});

  final bool frontCamera;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(
        frontCamera ? 'photos.account_visibility' : 'photos.patient_visibility',
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
