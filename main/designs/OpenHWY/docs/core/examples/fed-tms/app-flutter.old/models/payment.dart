import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('succeeded')
  succeeded,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

@JsonSerializable()
class Payment extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final double amount;
  final PaymentStatus status;
  final String method;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  @override
  List<Object?> get props => [id, userId, amount, status, method];
}
