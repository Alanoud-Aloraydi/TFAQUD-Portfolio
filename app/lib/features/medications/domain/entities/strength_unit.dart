enum StrengthUnit {
  milligram('mg'),
  microgram('mcg'),
  milligramPerMilliliter('mg/mL'),
  milligramPerFiveMilliliters('mg/5mL'),
  microgramPerDose('mcg/dose'),
  unitPerMilliliter('unit/mL'),
  percent('%');

  const StrengthUnit(this.apiValue);

  final String apiValue;

  static StrengthUnit fromApi(String value) =>
      values.firstWhere((unit) => unit.apiValue == value);
}
