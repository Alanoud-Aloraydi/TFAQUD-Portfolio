import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/widgets/circle_menu.dart';
import 'package:flutter/material.dart';

/// Opens the circle menu from the capsule of [selected] and does what is
/// picked: «إضافة دائرة», another circle, or nothing. [setMenuOpen] hides
/// the capsule while the menu is open; [isMounted] says whether the
/// capsule is still in the tree when the menu closes.
Future<void> chooseCircle(
  BuildContext context, {
  required List<CareCircleSummary> circles,
  required CareCircleSummary selected,
  required ValueChanged<String> onSelected,
  required VoidCallback? onAddCircle,
  required ValueChanged<bool> setMenuOpen,
  required bool Function() isMounted,
}) async {
  setMenuOpen(true);
  final String? picked = await showCircleMenu(
    context,
    circles: circles,
    selectedId: selected.id,
    name: selected.name,
    canAddCircle: onAddCircle != null,
  );
  if (!isMounted()) return;
  setMenuOpen(false);
  if (picked == null) return;
  if (picked == addCircleChoice) {
    onAddCircle?.call();
  } else if (picked != selected.id) {
    onSelected(picked);
  }
}
