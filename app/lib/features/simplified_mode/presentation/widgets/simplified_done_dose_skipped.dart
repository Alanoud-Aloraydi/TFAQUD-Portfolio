part of 'simplified_done_message.dart';

class SimplifiedDoneDoseSkipped extends SimplifiedDoneMessage {
  const SimplifiedDoneDoseSkipped(this.name);

  final String name;

  @override
  String text(BuildContext context) =>
      context.tr('simplified_mode.done_skipped', args: <String>[name]);
}
