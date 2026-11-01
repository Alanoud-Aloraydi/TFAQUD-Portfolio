import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:flutter/material.dart';

/// A field the person cannot change, in the design system's form row: the
/// small label on the right, the value after it, and a small note at the end
/// that says where the value comes from ("من حسابك", "حدده صاحب الطلب").
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.note,
    required this.child,
  });

  final String label;
  final String note;

  /// The value, or a spinner or a retry link while it loads.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InsetGroup(
      children: <Widget>[
        InsetFieldRow(
          label: label,
          trailing: Text(note, style: text.bodySmall),
          child: DefaultTextStyle.merge(style: text.bodyLarge, child: child),
        ),
      ],
    );
  }
}
