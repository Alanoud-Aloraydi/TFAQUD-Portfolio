/// [seconds] as minutes and seconds, such as 1:05.
String waitClock(int seconds) {
  final String minutes = (seconds ~/ 60).toString();
  final String rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}
