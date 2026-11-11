import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// «who recorded it»: the person's photo and name, the same under a dose, a
/// measurement and a reading.
class RecorderLine extends StatelessWidget {
  const RecorderLine({
    super.key,
    required this.name,
    required this.photoPath,
    this.avatarCode,
  });

  final String name;
  final String photoPath;
  final String? avatarCode;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PersonPhoto(
          name: name,
          photoPath: photoPath,
          avatarCode: avatarCode,
          size: AppSizes.iconSmall,
        ),
        const SizedBox(width: AppSpacing.tight),
        Flexible(
          child: Text(name, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
