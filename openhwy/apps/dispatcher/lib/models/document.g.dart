// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
      category: json['category'] as String,
      status: $enumDecode(_$DocumentStatusEnumMap, json['status']),
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      loadId: json['load_id'] as String?,
      fileUrl: json['file_url'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$DocumentTypeEnumMap[instance.type]!,
      'category': instance.category,
      'status': _$DocumentStatusEnumMap[instance.status]!,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'load_id': instance.loadId,
      'file_url': instance.fileUrl,
      'file_size': instance.fileSize,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.license: 'license',
  DocumentType.insurance: 'insurance',
  DocumentType.bill: 'bill',
  DocumentType.inspection: 'inspection',
  DocumentType.hazmat: 'hazmat',
  DocumentType.delivery: 'delivery',
  DocumentType.rateConfirmation: 'rate_confirmation',
  DocumentType.pod: 'pod',
  DocumentType.bol: 'bol',
  DocumentType.other: 'other',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.pending: 'pending',
  DocumentStatus.expired: 'expired',
  DocumentStatus.rejected: 'rejected',
};
