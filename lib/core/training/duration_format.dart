/// Formats an elapsed workout duration as `mm:ss`, or `h:mm:ss` once it
/// runs past an hour — shared by the active workout screen's timer chip and
/// the persistent active-workout bar so they always agree.
String formatElapsedDuration(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = elapsed.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
