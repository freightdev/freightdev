import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure: $message${code != null ? " (Code: $code)" : ""}';
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Network connection failed',
    String? code,
  }) : super(message: message, code: code);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    String message = 'Server error occurred',
    this.statusCode,
    String? code,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [message, code, statusCode];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    String message = 'Unauthorized access',
    String? code,
  }) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    String message = 'Validation failed',
    String? code,
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Cache error occurred',
    String? code,
  }) : super(message: message, code: code);
}

class ParseFailure extends Failure {
  const ParseFailure({
    String message = 'Failed to parse data',
    String? code,
  }) : super(message: message, code: code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'Resource not found',
    String? code,
  }) : super(message: message, code: code);
}
