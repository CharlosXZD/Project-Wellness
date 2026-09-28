/// Metric vs imperial display preference. Storage is always canonical
/// kg/cm in SQLite — this only controls how values are formatted for
/// display and parsed back from user input.
enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get label {
    switch (this) {
      case UnitSystem.metric:
        return 'Metric';
      case UnitSystem.imperial:
        return 'Imperial';
    }
  }
}

class Units {
  Units._();

  static const double _kgPerLb = 0.45359237;
  static const double _cmPerInch = 2.54;
  static const double _kmPerMile = 1.609344;

  static double kgToLbs(double kg) => kg / _kgPerLb;
  static double lbsToKg(double lbs) => lbs * _kgPerLb;
  static double cmToInches(double cm) => cm / _cmPerInch;
  static double inchesToCm(double inches) => inches * _cmPerInch;
  static double feetInchesToCm(int feet, double inches) =>
      inchesToCm(feet * 12 + inches);
  static double kmToMiles(double km) => km / _kmPerMile;
  static double milesToKm(double miles) => miles * _kmPerMile;

  static String distanceUnitLabel(UnitSystem system) =>
      system == UnitSystem.metric ? 'km' : 'mi';

  /// The step size a weight stepper/increment control should use.
  static double weightStep(UnitSystem system) =>
      system == UnitSystem.metric ? 2.5 : Units.lbsToKg(5);

  /// Snaps a stored kg/km value to the nearest 0.001 — every weight/distance
  /// stepper must call this after adding a delta (e.g. `Units.lbsToKg(5)`
  /// repeatedly), since values like that aren't exact in binary floating
  /// point: incrementing/decrementing several times drifts to things like
  /// `5.000000004` instead of `5.0`, which then leaks into the UI (e.g. the
  /// tap-to-type dialog) as raw noisy digits instead of a clean number.
  /// Rounding at the point of mutation — not just at display time — is what
  /// actually stops the drift from accumulating across repeated taps.
  ///
  /// Must stay finer than 0.01: an Imperial 5 lb step is ~2.267961 kg, which
  /// doesn't land on the old 0.01 kg grid, so rounding to it after every tap
  /// introduced its own ~0.002 kg bias *in the same direction* each time —
  /// invisible for a few taps, but compounding past ~55-60 lbs into enough
  /// error to flip the 1-decimal display back on (e.g. "60.1" instead of
  /// "60"), no matter how carefully that display step rounds. 0.001 kg is
  /// fine enough that this bias would need hundreds of taps to become
  /// visible, while still comfortably absorbing genuine floating-point
  /// noise (which sits around 1e-13).
  static double roundStorage(double value) => (value * 1000).round() / 1000;

  static String weightUnitLabel(UnitSystem system) =>
      system == UnitSystem.metric ? 'kg' : 'lbs';

  /// Formats a raw display value (already unit-converted) as a clean
  /// number — whole numbers always drop the decimal (never "160.0"). Rounds
  /// to [decimals] *before* checking for whole-number-ness, since unit
  /// conversions (kg<->lbs) leave binary floating-point noise like
  /// 159.999999996 that `value % 1 == 0` would miss, letting the noise leak
  /// into the UI as a spurious ".0"/".x" instead of the clean value the
  /// user actually expects to see.
  static String formatNumber(double value, {int decimals = 1}) {
    final rounded = double.parse(value.toStringAsFixed(decimals));
    return rounded % 1 == 0 ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(decimals);
  }

  /// Formats a canonical kg value for display, e.g. "72.5 kg" / "160 lbs".
  static String formatWeight(double kg, UnitSystem system, {int decimals = 1}) {
    final value = system == UnitSystem.metric ? kg : kgToLbs(kg);
    return '${formatNumber(value, decimals: decimals)} ${weightUnitLabel(system)}';
  }

  /// Formats a canonical cm value for display, e.g. "175 cm" / "5'9\"".
  static String formatHeight(double cm, UnitSystem system) {
    if (system == UnitSystem.metric) {
      return '${cm.toStringAsFixed(0)} cm';
    }
    final totalInches = cmToInches(cm).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  /// Parses a weight typed in [system]'s unit into canonical kg.
  static double? parseWeightToKg(String input, UnitSystem system) {
    // Spanish-locale keyboards type a decimal comma ("95,5").
    final value = double.tryParse(input.trim().replaceAll(',', '.'));
    if (value == null) return null;
    return system == UnitSystem.metric ? value : lbsToKg(value);
  }
}
