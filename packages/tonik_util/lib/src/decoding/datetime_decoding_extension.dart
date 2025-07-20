import 'package:timezone/timezone.dart' as tz;
import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Extension on DateTime to provide timezone-aware parsing.
///
/// This extension handles timezone information correctly:
/// - UTC strings return DateTime.utc objects
/// - Strings without timezone info return local DateTime objects
/// - Strings with timezone offsets return TZDateTime objects
extension DateTimeParsingExtension on DateTime {
  /// Parses an ISO8601 datetime string with proper timezone handling.
  ///
  /// Returns:
  /// - [DateTime] (UTC) for strings ending with 'Z'
  /// - [DateTime] (local) for strings without timezone information
  /// - [tz.TZDateTime] for strings with timezone offset information
  ///
  /// Throws [DecodingException] if the string is not a valid ISO8601 format.
  static DateTime parseWithTimeZone(String input) {
    if (input.isEmpty) {
      throw const InvalidFormatException(
        value: '',
        format: 'ISO8601 datetime string',
      );
    }

    // Handle different separator formats (T or space)
    final normalizedInput = input.replaceFirst(' ', 'T');

    // Check if it has timezone offset (±HH:MM or ±HHMM)
    final timezoneRegex = RegExp(r'[+-]\d{2}:?\d{2}$');
    final timezoneMatch = timezoneRegex.firstMatch(normalizedInput);

    if (timezoneMatch != null) {
      return _parseWithTimezoneOffset(normalizedInput, timezoneMatch);
    }

    // Parse as UTC (ends with Z) or local time (no timezone info)
    try {
      return DateTime.parse(normalizedInput);
    } on FormatException {
      throw InvalidFormatException(
        value: normalizedInput,
        format: 'ISO8601 datetime format',
      );
    }
  }

  /// Parses a datetime string with timezone offset.
  static tz.TZDateTime _parseWithTimezoneOffset(
    String input,
    RegExpMatch timezoneMatch,
  ) {
    final offsetString = timezoneMatch.group(0)!;
    final datetimeString = input.substring(
      0,
      input.length - offsetString.length,
    );

    final offset = _parseTimezoneOffset(offsetString);
    final localDateTime = DateTime.parse(datetimeString);
    final location = _findLocationForOffset(offset, localDateTime);

    // For standard offsets that have proper timezone locations, use them
    if (location.name != 'UTC' || offset == Duration.zero) {
      final utcDateTime = localDateTime.subtract(offset);
      
      final utcTz = tz.TZDateTime.utc(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
        utcDateTime.second,
        utcDateTime.millisecond,
        utcDateTime.microsecond,
      );
      
      return tz.TZDateTime.from(utcTz, location);
    }
    
    // For unusual offsets that don't have proper timezone locations,
    // fall back to UTC and convert the time correctly
    final utcDateTime = localDateTime.subtract(offset);
    
    return tz.TZDateTime.utc(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
      utcDateTime.hour,
      utcDateTime.minute,
      utcDateTime.second,
      utcDateTime.millisecond,
      utcDateTime.microsecond,
    );
  }

  /// Finds the best timezone location for a given offset at a
  /// specific datetime.
  ///
  /// This leverages the timezone package's comprehensive database to find
  /// locations that match the offset, taking into account DST changes.
  static tz.Location _findLocationForOffset(
    Duration offset,
    DateTime dateTime,
  ) {
    final offsetMinutes = offset.inMinutes;
    final timestamp = dateTime.millisecondsSinceEpoch;

    for (final locationName in _commonLocations) {
      try {
        final location = tz.getLocation(locationName);
        final timeZone = location.timeZone(timestamp);
        if (timeZone.offset == offsetMinutes * 60 * 1000) {
          return location;
        }
      } on tz.LocationNotFoundException {
        // Location doesn't exist, continue
      }
    }

    final matchingLocations = <tz.Location>[];
    for (final location in tz.timeZoneDatabase.locations.values) {
      final timeZone = location.timeZone(timestamp);
      if (timeZone.offset == offsetMinutes * 60 * 1000) {
        matchingLocations.add(location);
      }
    }

    if (matchingLocations.isNotEmpty) {
      // Prefer locations that don't use deprecated prefixes
      final preferredMatches =
          matchingLocations
              .where(
                (loc) =>
                    !loc.name.startsWith('US/') &&
                    !loc.name.startsWith('Etc/') &&
                    !loc.name.contains('GMT'),
              )
              .toList();

      if (preferredMatches.isNotEmpty) {
        return preferredMatches.first;
      }

      return matchingLocations.first;
    }

    return _createFixedOffsetLocation(offset);
  }

  /// Creates a location with a fixed offset when no matching timezone is found.
  static tz.Location _createFixedOffsetLocation(Duration offset) {
    final offsetMinutes = offset.inMinutes;
    
    // For standard hour offsets, try to use Etc/GMT locations
    if (offsetMinutes % 60 == 0) {
      final offsetHours = offsetMinutes ~/ 60;
      // Use Etc/GMT format which is supported by the timezone database
      // Note: Etc/GMT offsets are inverted (Etc/GMT+5 is actually GMT-5)
      final etcName =
          offset.isNegative
              ? 'Etc/GMT+${offsetHours.abs()}'
              : 'Etc/GMT-${offsetHours.abs()}';

      try {
        return tz.getLocation(etcName);
      } on tz.LocationNotFoundException {
        // Fall through to UTC
      }
    }
    
    // For non-standard offsets, fall back to UTC
    // This is a limitation - the timezone package doesn't easily support
    // arbitrary fixed offsets, so we use UTC as fallback
    return tz.getLocation('UTC');
  }

  /// Parses timezone offset string (±HH:MM or ±HHMM) into Duration.
  static Duration _parseTimezoneOffset(String offsetString) {
    // Remove optional colon for compact format
    final normalized = offsetString.replaceAll(':', '');

    if (normalized.length != 5) {
      throw InvalidFormatException(
        value: offsetString,
        format: '±HHMM or ±HH:MM timezone offset',
      );
    }

    final sign = normalized[0] == '+' ? 1 : -1;
    final hoursStr = normalized.substring(1, 3);
    final minutesStr = normalized.substring(3, 5);

    final hours = int.parse(hoursStr);
    final minutes = int.parse(minutesStr);

    // Let Duration handle any overflow gracefully
    return Duration(hours: sign * hours, minutes: sign * minutes);
  }
}

/// Commonly used timezone locations, prioritized for offset matching.
/// Based on major cities and avoiding deprecated location names.
const _commonLocations = [
  // Europe
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Rome',
  'Europe/Madrid',
  'Europe/Amsterdam',
  'Europe/Brussels',
  'Europe/Vienna',
  'Europe/Zurich',
  'Europe/Stockholm',
  'Europe/Oslo',
  'Europe/Copenhagen',
  'Europe/Helsinki',
  'Europe/Warsaw',
  'Europe/Prague',
  'Europe/Budapest',
  'Europe/Athens',
  'Europe/Istanbul',
  'Europe/Moscow',

  // Americas
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'America/Vancouver',
  'America/Montreal',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'America/Buenos_Aires',
  'America/Lima',
  'America/Bogota',
  'America/Caracas',
  'America/Santiago',
  'America/Montevideo',

  // Asia
  'Asia/Tokyo',
  'Asia/Seoul',
  'Asia/Shanghai',
  'Asia/Hong_Kong',
  'Asia/Singapore',
  'Asia/Bangkok',
  'Asia/Jakarta',
  'Asia/Manila',
  'Asia/Kuala_Lumpur',
  'Asia/Kolkata',
  'Asia/Mumbai',
  'Asia/Karachi',
  'Asia/Dubai',
  'Asia/Riyadh',
  'Asia/Baghdad',
  'Asia/Tehran',
  'Asia/Kabul',
  'Asia/Tashkent',
  'Asia/Almaty',

  // Australia & Pacific
  'Australia/Sydney',
  'Australia/Melbourne',
  'Australia/Brisbane',
  'Australia/Perth',
  'Australia/Adelaide',
  'Pacific/Auckland',
  'Pacific/Honolulu',
  'Pacific/Fiji',

  // Africa
  'Africa/Cairo',
  'Africa/Johannesburg',
  'Africa/Lagos',
  'Africa/Nairobi',
  'Africa/Casablanca',
  'Africa/Tunis',
  'Africa/Algiers',

  // UTC
  'UTC',
];
