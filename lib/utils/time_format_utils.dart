/// Formats a duration (in seconds) into a time string.
/// 
/// - Returns "HH:MM:SS" if the duration includes hours.
/// - Returns "MM:SS" if hours are zero.
/// 
/// Examples:
/// ```dart
/// formatTimeToClock(45);      // "00:45"
/// formatTimeToClock(125);     // "02:05"
/// formatTimeToClock(3661);    // "01:01:01"
/// ```
String secondsToTimeString(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final hh = hours.toString().padLeft(2, '0');
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  return hours > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
}