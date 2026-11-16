import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The heading of the contact card: whether it is adding a contact or
/// changing one, and the gap under it.
class ContactFormTitle extends StatelessWidget {
  const ContactFormTitle({super.key, required this.isNew});

  final bool isNew;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Semantics(
        header: true,
        child: Text(
          context.tr(
            isNew ? 'circles.contact_new_title' : 'circles.contact_edit_title',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ],
  );
}
