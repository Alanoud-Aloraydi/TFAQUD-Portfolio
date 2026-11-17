import 'package:app/features/simplified_mode/presentation/widgets/care_icon_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A row of this mode's «حسابي»: a coloured square, what the switch
/// decides, and the switch — big enough to hit at this mode's sizes.
class SimplifiedSwitchRow extends StatelessWidget {
  const SimplifiedSwitchRow({
    super.key,
    required this.icon,
    required this.background,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color background;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Row(
        children: <Widget>[
          CareIconTile(icon: icon, background: background),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: SimplifiedStyle.label(SimplifiedStyle.body),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: SimplifiedStyle.success,
          ),
        ],
      ),
    ),
  );
}
