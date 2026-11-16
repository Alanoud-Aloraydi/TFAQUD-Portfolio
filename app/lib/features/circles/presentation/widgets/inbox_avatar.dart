import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// The round avatar of the person an inbox card is about: their picture when
/// they picked one, else the first letter of their name.
class InboxAvatar extends StatelessWidget {
  const InboxAvatar({
    super.key,
    required this.name,
    required this.background,
    required this.foreground,
    this.avatarCode,
  });

  final String name;
  final Color background;
  final Color foreground;
  final String? avatarCode;

  /// The first letter of a name, «؟» when there is no name.
  static String initial(String name) {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '؟' : trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    if (avatarCodes.contains(avatarCode)) {
      return PersonPhoto(
        name: name,
        photoPath: '',
        avatarCode: avatarCode,
        size: AppSizes.avatar,
      );
    }
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initial(name),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}
