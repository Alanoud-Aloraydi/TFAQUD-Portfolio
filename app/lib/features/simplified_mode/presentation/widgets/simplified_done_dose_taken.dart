part of 'simplified_done_message.dart';

class SimplifiedDoneDoseTaken extends SimplifiedDoneMessage {
  const SimplifiedDoneDoseTaken(this.name, this.at);

  final String name;
  final DateTime at;

  @override
  String text(BuildContext context) {
    return context.tr(
      'simplified_mode.done_dose',
      args: <String>[name, simplifiedClockAt(context, at)],
    );
  }
}
