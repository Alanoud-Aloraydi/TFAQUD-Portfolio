import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Opens the "what do you want to add?" sheet. Options stay disabled until
/// their destination screens exist.
Future<void> showAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => const _AddSheet(),
  );
}

class _AddSheet extends StatelessWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.tr('add.title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _AddOption(
              icon: Icons.medication_outlined,
              title: context.tr('add.medication'),
              hint: context.tr('add.medication_hint'),
            ),
            _AddOption(
              icon: Icons.water_drop_outlined,
              title: context.tr('add.measurement'),
              hint: context.tr('add.measurement_hint'),
            ),
            _AddOption(
              icon: Icons.event_outlined,
              title: context.tr('add.appointment'),
              hint: context.tr('add.appointment_hint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: false,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(hint),
      ),
    );
  }
}
