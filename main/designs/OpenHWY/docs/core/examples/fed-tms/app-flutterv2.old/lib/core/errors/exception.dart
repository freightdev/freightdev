abstract class Exception implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  Exception({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Exception: $message${code != null ? " (Code: $code)" : ""}';
}

class NetworkException extends Exception {
  NetworkException({
    String message = 'Network error occurred',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ServerException extends Exception {
  final int? statusCode;

  ServerException({
    String message = 'Server error occurred',
    this.statusCode,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'ServerException: $message${statusCode != null ? " (Status: $statusCode)" : ""}';
}

class UnauthorizedException extends Exception {
  UnauthorizedException({
    String message = 'Unauthorized access',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ValidationException extends Exception {
  ValidationException({
    String message = 'Validation failed',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class CacheException extends Exception {
  CacheException({
    String message = 'Cache error occurred',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ParseException extends Exception {
  ParseException({
    String message = 'Failed to parse data',
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}
