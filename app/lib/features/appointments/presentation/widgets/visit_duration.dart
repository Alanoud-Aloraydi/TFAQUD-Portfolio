/// «4:05» for a length in [seconds], and «--:--» when there is none yet.
String visitDuration(int? seconds) {
  if (seconds == null) return '--:--';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
