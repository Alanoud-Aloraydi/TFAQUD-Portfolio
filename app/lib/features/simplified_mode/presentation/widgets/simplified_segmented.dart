import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Two or three big choices in one capsule («ضغط الدم | سكر الدم»).
class SimplifiedSegmented<T> extends StatelessWidget {
  const SimplifiedSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SimplifiedStyle.surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: SimplifiedStyle.control, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<T, String> entry in segments.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == selected,
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: SimplifiedStyle.touch,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == selected
                          ? SimplifiedStyle.surface
                          : SimplifiedStyle.clear,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      entry.value,
                      style: entry.key == selected
                          ? SimplifiedStyle.head(SimplifiedStyle.body)
                          : SimplifiedStyle.text(
                              SimplifiedStyle.body,
                              color: SimplifiedStyle.ink,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
