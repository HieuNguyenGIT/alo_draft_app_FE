import 'package:flutter/foundation.dart';

class AppLogger {
  static String _environment = 'production'; // Default to production

  // Emoji indicators
  static const String _infoEmoji = '🔵';
  static const String _errorEmoji = '🔴';
  static const String _warningEmoji = '🟠';

  // Initialize the logger with the current environment
  static void init(String environment) {
    _environment = environment.toLowerCase();
  }

  // Log method that checks the environment before logging
  static void log(String message) {
    if (_environment == 'local' ||
        _environment == 'staging' ||
        _environment == 'qaproduction') {
      debugPrint('$_infoEmoji AppLogger: $message');
    }
  }

  // Error logging
  static void error(String message) {
    if (_environment == 'local' ||
        _environment == 'staging' ||
        _environment == 'qaproduction') {
      debugPrint('$_errorEmoji AppLogger ERROR: $message');
    }
  }

  // Warning logging
  static void warn(String message) {
    if (_environment == 'local' ||
        _environment == 'staging' ||
        _environment == 'qaproduction') {
      debugPrint('$_warningEmoji AppLogger WARNING: $message');
    }
  }

  static void logLongText(String message, {int chunkSize = 500}) {
    if (_environment == 'local' ||
        _environment == 'staging' ||
        _environment == 'qaproduction') {
      int colonIndex = message.indexOf(':');
      String tag = colonIndex != -1
          ? message.substring(0, colonIndex).trim()
          : 'LongText';
      String content =
          colonIndex != -1 ? message.substring(colonIndex + 1).trim() : message;

      if (content.length <= chunkSize) {
        log(message);
      } else {
        int start = 0;
        int end = chunkSize;
        int part = 1;
        while (start < content.length) {
          log('$tag (Part $part): ${content.substring(start, end)}');
          start = end;
          end = (start + chunkSize) > content.length
              ? content.length
              : start + chunkSize;
          part++;
        }
      }
    }
  }
}
