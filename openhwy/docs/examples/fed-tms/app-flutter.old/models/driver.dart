import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'driver.g.dart';

enum DriverStatus {
  @JsonValue('online')
  online,
  @JsonValue('away')
  away,
  @JsonValue('offline')
  offline,
  @JsonValue('on_break')
  onBreak,
  @JsonValue('driving')
  driving,
}

@JsonSerializable()
class Driver extends Equatable {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  final String? phone;
  final DriverStatus status;
  @JsonKey(name: 'current_location')
  final String? currentLocation;
  @JsonKey(name: 'current_lat')
  final double? currentLat;
  @JsonKey(name: 'current_lng')
  final double? currentLng;
  @JsonKey(name: 'active_loads')
  final int activeLoads;
  @JsonKey(name: 'total_loads')
  final int totalLoads;
  @JsonKey(name: 'cdl_number')
  final String? cdlNumber;
  @JsonKey(name: 'cdl_expiry')
  final DateTime? cdlExpiry;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;
  final double? rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.status,
    this.currentLocation,
    this.currentLat,
    this.currentLng,
    this.activeLoads = 0,
    this.totalLoads = 0,
    this.cdlNumber,
    this.cdlExpiry,
    this.vehicleId,
    this.vehiclePlate,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  Map<String, dynamic> toJson() => _$DriverToJson(this);

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        status,
        activeLoads,
        rating,
      ];

  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DriverStatus? status,
    String? currentLocation,
    double? currentLat,
    double? currentLng,
    int? activeLoads,
    int? totalLoads,
    String? cdlNumber,
    DateTime? cdlExpiry,
    String? vehicleId,
    String? vehiclePlate,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      activeLoads: activeLoads ?? this.activeLoads,
      totalLoads: totalLoads ?? this.totalLoads,
      cdlNumber: cdlNumber ?? this.cdlNumber,
      cdlExpiry: cdlExpiry ?? this.cdlExpiry,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
