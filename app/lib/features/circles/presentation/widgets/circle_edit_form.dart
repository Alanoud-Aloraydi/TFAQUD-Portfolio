import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_form_state.dart';
import 'package:flutter/material.dart';

/// What «تعديل الدائرة» holds: the patient's picture with «تغيير الصورة»,
/// the circle's name, and the save button.
class CircleEditForm extends StatefulWidget {
  const CircleEditForm({
    super.key,
    required this.circleId,
    required this.name,
    required this.overview,
  });

  final String circleId;

  /// The name the circle has now.
  final String name;
  final CircleOverview overview;

  @override
  State<CircleEditForm> createState() => CircleEditFormState();
}
