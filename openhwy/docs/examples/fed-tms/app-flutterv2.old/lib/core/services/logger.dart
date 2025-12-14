import 'package:flutter/foundation.dart';
import '../configs/flavors.dart';

class LoggerService {
  static bool _initialized = false;
  static FlavorType? _flavor;

  static void init(FlavorType flavor) {
    _flavor = flavor;
    _initialized = true;
    info('LoggerService initialized for ${flavor.name}');
  }

  static bool get _shouldLog {
    if (!_initialized) return false;
    return _flavor != FlavorType.prod || kDebugMode;
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      debugPrint('= [DEBUG] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  static void info(String message) {
    if (_shouldLog) {
      debugPrint('9 [INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (_shouldLog) {
      debugPrint('  [WARNING] $message');
      if (error != null) debugPrint('Error: $error');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('L [ERROR] $message');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  static void network(String method, String url, {int? statusCode, Object? data}) {
    if (_shouldLog) {
      debugPrint('< [$method] $url ${statusCode != null ? "($statusCode)" : ""}');
      if (data != null) debugPrint('Data: $data');
    }
  }
}
