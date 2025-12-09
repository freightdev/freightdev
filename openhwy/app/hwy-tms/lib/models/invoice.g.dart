// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: json['id'] as String,
      number: json['number'] as String,
      loadId: json['load_id'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      status: $enumDecode(_$InvoiceStatusEnumMap, json['status']),
      dueDate: DateTime.parse(json['due_date'] as String),
      issuedDate: DateTime.parse(json['issued_date'] as String),
      paidDate: json['paid_date'] == null
          ? null
          : DateTime.parse(json['paid_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'load_id': instance.loadId,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'amount': instance.amount,
      'paid_amount': instance.paidAmount,
      'remaining_amount': instance.remainingAmount,
      'status': _$InvoiceStatusEnumMap[instance.status]!,
      'due_date': instance.dueDate.toIso8601String(),
      'issued_date': instance.issuedDate.toIso8601String(),
      'paid_date': instance.paidDate?.toIso8601String(),
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.draft: 'draft',
  InvoiceStatus.pending: 'pending',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.partial: 'partial',
  InvoiceStatus.cancelled: 'cancelled',
  InvoiceStatus.overdue: 'overdue',
};
