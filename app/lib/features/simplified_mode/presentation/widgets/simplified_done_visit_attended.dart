part of 'simplified_done_message.dart';

class SimplifiedDoneVisitAttended extends SimplifiedDoneMessage {
  const SimplifiedDoneVisitAttended(this.title);

  /// The visit's name, as its card says it.
  final String title;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_attended', args: <String>[title]);
}
