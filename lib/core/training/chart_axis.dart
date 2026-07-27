/// Rounds a raw "range / desired divisions" value up to a human-friendly
/// step (1, 2, 5, 10, 25, 50, 100, ...) so a chart's Y-axis labels land on
/// round numbers spaced evenly apart, instead of `fl_chart`'s default
/// auto-interval picking an arbitrary decimal that can land a label right
/// on top of the axis's own max value.
double niceAxisInterval(double raw) {
  if (raw <= 0) return 1;
  const steps = [1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0];
  for (final step in steps) {
    if (raw <= step) return step;
  }
  return raw.ceilToDouble();
}
