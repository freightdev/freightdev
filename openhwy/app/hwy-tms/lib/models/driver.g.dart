// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: $enumDecode(_$DriverStatusEnumMap, json['status']),
      currentLocation: json['current_location'] as String?,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      activeLoads: (json['active_loads'] as num?)?.toInt() ?? 0,
      totalLoads: (json['total_loads'] as num?)?.toInt() ?? 0,
      cdlNumber: json['cdl_number'] as String?,
      cdlExpiry: json['cdl_expiry'] == null
          ? null
          : DateTime.parse(json['cdl_expiry'] as String),
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'status': _$DriverStatusEnumMap[instance.status]!,
      'current_location': instance.currentLocation,
      'current_lat': instance.currentLat,
      'current_lng': instance.currentLng,
      'active_loads': instance.activeLoads,
      'total_loads': instance.totalLoads,
      'cdl_number': instance.cdlNumber,
      'cdl_expiry': instance.cdlExpiry?.toIso8601String(),
      'vehicle_id': instance.vehicleId,
      'vehicle_plate': instance.vehiclePlate,
      'rating': instance.rating,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$DriverStatusEnumMap = {
  DriverStatus.online: 'online',
  DriverStatus.away: 'away',
  DriverStatus.offline: 'offline',
  DriverStatus.onBreak: 'on_break',
  DriverStatus.driving: 'driving',
};
