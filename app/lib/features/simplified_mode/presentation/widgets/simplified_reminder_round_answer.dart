import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedReminderRoundAnswer extends StatelessWidget {
  const SimplifiedReminderRoundAnswer({
    super.key,
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final VoidCallback? onTap;

  /// The round button and the word under it are one answer: an elderly
  /// user often taps the word, so the whole column takes the tap, and a
  /// screen reader hears it as one button named by the word.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          width: 130,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: SimplifiedStyle.answer,
                height: SimplifiedStyle.answer,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: fill,
                    foregroundColor: ink,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(icon, size: 46),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: SimplifiedStyle.head(21, color: SimplifiedStyle.surface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
