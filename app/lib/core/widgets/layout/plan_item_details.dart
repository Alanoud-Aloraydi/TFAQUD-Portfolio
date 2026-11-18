import 'package:app/core/widgets/layout/expand_reveal.dart';
import 'package:flutter/material.dart';

/// The details of a [PlanItemCard] under a line, sliding down from the line
/// that opens them when [open].
class PlanItemDetails extends StatelessWidget {
  const PlanItemDetails({super.key, required this.open, required this.details});

  final bool open;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    return ExpandReveal(
      open: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[const Divider(), ...details],
      ),
    );
  }
}
