import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/auth/supabase_auth/auth_util.dart';

bool checkIfTimeIsBetween(
  String startTimeStr,
  String endTimeStr,
  String selectedTimeStr,
) {
  final startMinutes = _minutesFromTimeString(startTimeStr);
  final endMinutes = _minutesFromTimeString(endTimeStr);
  final selectedMinutes = _minutesFromTimeString(selectedTimeStr);

  if (startMinutes == null || endMinutes == null || selectedMinutes == null) {
    return false;
  }

  return selectedMinutes > startMinutes && selectedMinutes < endMinutes;
}

int calculateGestationalAgeInWeeks(DateTime lnmp) {
  final currentDate = DateTime.now();
  final difference = currentDate.difference(lnmp);

  final weeks = (difference.inDays / 7).floor();

  return weeks;
}

int calculateTrimester(int gestetionalAge) {
  if (gestetionalAge <= 13) {
    return 1;
  } else if (gestetionalAge <= 26) {
    return 2;
  } else {
    return 3;
  }
}

int nextWeek(
  int valueToAdd,
  int week,
) {
  return week + valueToAdd;
}

double? stringToDouble(String value) {
  try {
    return double.parse(value);
  } catch (e) {
    print('Error parsing string: $value');
    return null;
  }
}

int? stringToInt(String value) {
  try {
    return int.parse(value);
  } catch (e) {
    print('Error parsing string: $value');
    return null;
  }
}

String? bloodPressureConversion(String bp) {
  try {
    var parts = bp.split('/');
    if (parts.length != 2) throw FormatException();

    int systolic = int.parse(parts[0].trim());
    int diastolic = int.parse(parts[1].trim());

    if (systolic >= 160 || diastolic >= 90) {
      return 'Severely High';
    } else if ((systolic >= 140 && systolic < 160) ||
        (diastolic >= 80 && diastolic < 90)) {
      return 'Moderately High';
    } else if ((systolic >= 90 && systolic < 120) ||
        (diastolic >= 60 && diastolic < 80)) {
      return 'Normal';
    } else if (systolic < 90 && diastolic < 60) {
      return 'Low';
    } else {
      return 'Out of Classification';
    }
  } catch (e) {
    return 'Invalid Input';
  }
}

String? checkHydrationLevel(String input) {
  try {
    double hydrationValue = double.parse(input.trim());

    if (hydrationValue >= 1.005 && hydrationValue <= 1.030) {
      return 'Well hydrated';
    } else if (hydrationValue < 1.005) {
      return 'Fluid overload';
    } else if (hydrationValue > 1.030) {
      return 'Dehydrated';
    } else {
      return 'Invalid Value';
    }
  } catch (e) {
    return 'Invalid Input';
  }
}

String? checkpH(String input) {
  try {
    double phValue = double.parse(input.trim());

    if (phValue >= 4.0 && phValue <= 8.0) {
      return 'Normal';
    } else if (phValue > 8.0) {
      return 'Abnormal';
    } else {
      return 'Out of Range';
    }
  } catch (e) {
    return 'Invalid Input';
  }
}

String? classifyPulse(int pulse) {
  if (pulse >= 110 && pulse <= 160) {
    return 'Normal';
  } else if (pulse > 160) {
    return 'Distressed';
  } else if (pulse < 100) {
    return 'Low';
  } else {
    return 'Unknown';
  }
}

List<String> thirtyMinuteIntervals(
  String startTime,
  String endTime,
) {
  List<String> intervals = [];

  final parsedCurrentMinutes = _minutesFromTimeString(startTime);
  final parsedEndMinutes = _minutesFromTimeString(endTime);

  if (parsedCurrentMinutes == null ||
      parsedEndMinutes == null ||
      parsedCurrentMinutes >= parsedEndMinutes) {
    return intervals;
  }

  var currentMinutes = parsedCurrentMinutes;
  final int endMinutes = parsedEndMinutes;

  while (currentMinutes < endMinutes) {
    final startHour = currentMinutes ~/ 60;
    final startMinute = currentMinutes % 60;

    // Skip lunchtime
    if (startHour == 13 && startMinute == 0) {
      currentMinutes += 60;
      continue;
    }

    String formattedHour = startHour.toString().padLeft(2, '0');
    String formattedMinute = startMinute.toString().padLeft(2, '0');

    intervals.add('$formattedHour:$formattedMinute');

    currentMinutes += 30;
  }

  return intervals;
}

int? _minutesFromTimeString(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final match =
      RegExp(r'^(\d{1,2})(?::(\d{1,2}))?(?::\d{1,2})?\s*([aApP][mM])?$')
          .firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '0');
  if (hour == null || minute == null || minute < 0 || minute > 59) {
    return null;
  }

  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem != null) {
    if (hour < 1 || hour > 12) {
      return null;
    }
    if (meridiem == 'pm' && hour != 12) {
      hour += 12;
    }
    if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }
  } else if (hour < 0 || hour > 23) {
    return null;
  }

  return hour * 60 + minute;
}

DocumentReference stringToRef(String docID) {
  // converts a string to a reference
  return SupabaseDatabase.instance.doc(docID);
}
