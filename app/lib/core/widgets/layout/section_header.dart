import 'package:flutter/material.dart';

/// Plain label above a group of cards or a list (e.g. «جدول اليوم»),
/// with an optional trailing action such as an "add" link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget label = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
    if (trailing == null) return label;
    return Row(children: [Expanded(child: label), trailing!]);
  }
}
