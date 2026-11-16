import 'package:app/features/circles/domain/entities/list_answer.dart';
import 'package:equatable/equatable.dart';

/// The chronic conditions the user chose.
class ConditionsDraft extends Equatable {
  const ConditionsDraft.none()
    : answer = ListAnswer.none,
      codes = const <String>[],
      other = null;

  const ConditionsDraft.listed({required this.codes, this.other})
    : answer = ListAnswer.listed;

  final ListAnswer answer;

  /// Codes of the chosen conditions. Empty for [ListAnswer.none].
  final List<String> codes;

  /// The typed text of the "other" condition, when "other" is in [codes].
  final String? other;

  /// [current] with [code] added ([has]) or taken out, every other answer
  /// kept. Taking out the last one answers "none"; an unanswered list
  /// (null) stays unanswered when [code] is taken out, since saying the
  /// patient lacks one condition says nothing of the rest.
  static ConditionsDraft? withCode(
    ConditionsDraft? current,
    String code, {
    required bool has,
  }) {
    final List<String> codes = <String>[
      for (final String one in current?.codes ?? const <String>[])
        if (one != code) one,
      if (has) code,
    ];
    if (codes.isNotEmpty) {
      return ConditionsDraft.listed(
        codes: codes,
        other: codes.contains('other') ? current?.other : null,
      );
    }
    return current == null ? null : const ConditionsDraft.none();
  }

  @override
  List<Object?> get props => [answer, codes, other];
}
