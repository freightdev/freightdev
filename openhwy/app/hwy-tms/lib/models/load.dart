import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'load.g.dart';

enum LoadStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('booked')
  booked,
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class Load extends Equatable {
  final String id;
  final String reference;
  final String origin;
  final String destination;
  @JsonKey(name: 'origin_lat')
  final double? originLat;
  @JsonKey(name: 'origin_lng')
  final double? originLng;
  @JsonKey(name: 'destination_lat')
  final double? destinationLat;
  @JsonKey(name: 'destination_lng')
  final double? destinationLng;
  final LoadStatus status;
  final double rate;
  final int? distance;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  final String? eta;
  final int? progress;
  @JsonKey(name: 'pickup_date')
  final DateTime? pickupDate;
  @JsonKey(name: 'delivery_date')
  final DateTime? deliveryDate;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Load({
    required this.id,
    required this.reference,
    required this.origin,
    required this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    required this.status,
    required this.rate,
    this.distance,
    this.driverId,
    this.driverName,
    this.eta,
    this.progress,
    this.pickupDate,
    this.deliveryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Load.fromJson(Map<String, dynamic> json) => _$LoadFromJson(json);
  Map<String, dynamic> toJson() => _$LoadToJson(this);

  @override
  List<Object?> get props => [
        id,
        reference,
        origin,
        destination,
        status,
        rate,
        distance,
        driverId,
        eta,
        progress,
      ];

  Load copyWith({
    String? id,
    String? reference,
    String? origin,
    String? destination,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    LoadStatus? status,
    double? rate,
    int? distance,
    String? driverId,
    String? driverName,
    String? eta,
    int? progress,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Load(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      status: status ?? this.status,
      rate: rate ?? this.rate,
      distance: distance ?? this.distance,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      eta: eta ?? this.eta,
      progress: progress ?? this.progress,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
