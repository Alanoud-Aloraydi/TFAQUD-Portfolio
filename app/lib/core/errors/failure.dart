import 'package:equatable/equatable.dart';

/// Base failure class.
///
/// [messageKey] is a key in `assets/translations`; the screen translates it.
/// The API supplies codes, and the app shows its own Arabic text.
abstract class Failure extends Equatable {
  final String messageKey;

  const Failure([this.messageKey = 'error.unknown']);

  @override
  List<Object?> get props => [messageKey];
}
