/// The glucose table a meal state is read from: `fasting` for fasting or
/// before a meal, else `after_meal` (after a meal, at bedtime, or none).
String normalRangeState(String? state) =>
    state == 'fasting' || state == 'before_meal' ? 'fasting' : 'after_meal';
