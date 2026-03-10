import 'package:flutter/foundation.dart';

class TimeFormatter {
  /// Convert 24-hour time string (e.g., "14:30" or "08:00;14:30") to 12-hour AM/PM format
  static String to12HourFormat(String timeString) {
    try {
      // Split multiple times (e.g., "08:00;14:30;20:00")
      final times = timeString.split(';');
      
      final formattedTimes = times.map((time) {
        return _singleTimeTo12Hour(time);
      }).toList();
      
      return formattedTimes.join(', ');
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return timeString.replaceAll(';', ', ');
    }
  }
  
  /// Convert single 24-hour time (e.g., "14:30") to 12-hour AM/PM format
  static String _singleTimeTo12Hour(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        
        // Convert to AM/PM format
        final amPm = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        
        return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
      }
      return time; // Return original if parsing fails
    } catch (e) {
      debugPrint('Error formatting single time: $e');
      return time;
    }
  }
  
  /// Convert DateTime to 12-hour AM/PM format
  static String dateTimeTo12HourFormat(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
  }
  
  /// Parse hour and minute to 12-hour AM/PM format
  static String hourMinuteTo12Hour(int hour, int minute) {
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
  }
  
  /// Format date nicely (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = monthNames[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    return '$month $day, $year';
  }
}