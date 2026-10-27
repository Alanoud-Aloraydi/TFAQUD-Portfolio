import 'package:flutter/material.dart';

/// One choice of a [OptionChips] group: the API code and the text shown.
class ChipOption {
  const ChipOption(this.code, this.label);

  final String code;
  final String label;
}

/// A group of chips that wraps onto several lines. Whether the group is a
/// single choice or a multiple choice is decided by what [onTap] does; the
/// chips only show which codes are chosen ([isSelected]).
class OptionChips extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final List<ChipOption> options;
  final bool Function(String code) isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final ChipOption option in options)
          FilterChip(
            label: Text(option.label),
            selected: isSelected(option.code),
            onSelected: (_) => onTap(option.code),
          ),
      ],
    );
  }
}
