/// How fast «استماع» reads, chosen in «حسابي»: «بطيئة», «عادية», «سريعة».
/// Its [rate] is the speech plugin's, where 0.5 is the phone's own pace on
/// iOS; «عادية» keeps the pace the mode always had.
enum SimplifiedSpeechRate {
  slow(0.35),
  normal(0.45),
  fast(0.55);

  const SimplifiedSpeechRate(this.rate);

  final double rate;
}
