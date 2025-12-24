import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'invoice.g.dart';

enum InvoiceStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('partial')
  partial,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('overdue')
  overdue,
}

@JsonSerializable()
class Invoice extends Equatable {
  final String id;
  final String number;
  @JsonKey(name: 'load_id')
  final String? loadId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  final double amount;
  @JsonKey(name: 'paid_amount')
  final double paidAmount;
  @JsonKey(name: 'remaining_amount')
  final double remainingAmount;
  final InvoiceStatus status;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @JsonKey(name: 'issued_date')
  final DateTime issuedDate;
  @JsonKey(name: 'paid_date')
  final DateTime? paidDate;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.number,
    this.loadId,
    this.driverId,
    this.driverName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.remainingAmount,
    required this.status,
    required this.dueDate,
    required this.issuedDate,
    this.paidDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  @override
  List<Object?> get props => [
        id,
        number,
        amount,
        paidAmount,
        status,
        dueDate,
      ];

  Invoice copyWith({
    String? id,
    String? number,
    String? loadId,
    String? driverId,
    String? driverName,
    double? amount,
    double? paidAmount,
    double? remainingAmount,
    InvoiceStatus? status,
    DateTime? dueDate,
    DateTime? issuedDate,
    DateTime? paidDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      loadId: loadId ?? this.loadId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      issuedDate: issuedDate ?? this.issuedDate,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
