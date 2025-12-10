// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Load _$LoadFromJson(Map<String, dynamic> json) => Load(
      id: json['id'] as String,
      reference: json['reference'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      originLat: (json['origin_lat'] as num?)?.toDouble(),
      originLng: (json['origin_lng'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble(),
      status: $enumDecode(_$LoadStatusEnumMap, json['status']),
      rate: (json['rate'] as num).toDouble(),
      distance: (json['distance'] as num?)?.toInt(),
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      eta: json['eta'] as String?,
      progress: (json['progress'] as num?)?.toInt(),
      pickupDate: json['pickup_date'] == null
          ? null
          : DateTime.parse(json['pickup_date'] as String),
      deliveryDate: json['delivery_date'] == null
          ? null
          : DateTime.parse(json['delivery_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LoadToJson(Load instance) => <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'origin': instance.origin,
      'destination': instance.destination,
      'origin_lat': instance.originLat,
      'origin_lng': instance.originLng,
      'destination_lat': instance.destinationLat,
      'destination_lng': instance.destinationLng,
      'status': _$LoadStatusEnumMap[instance.status]!,
      'rate': instance.rate,
      'distance': instance.distance,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'eta': instance.eta,
      'progress': instance.progress,
      'pickup_date': instance.pickupDate?.toIso8601String(),
      'delivery_date': instance.deliveryDate?.toIso8601String(),
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$LoadStatusEnumMap = {
  LoadStatus.pending: 'pending',
  LoadStatus.booked: 'booked',
  LoadStatus.inTransit: 'in_transit',
  LoadStatus.delivered: 'delivered',
  LoadStatus.cancelled: 'cancelled',
};
