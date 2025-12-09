import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'company.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Company extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? legalName;

  @HiveField(3)
  final String? ein;

  @HiveField(4)
  final String? mcNumber;

  @HiveField(5)
  final String? dotNumber;

  @HiveField(6)
  final String? address;

  @HiveField(7)
  final String? city;

  @HiveField(8)
  final String? state;

  @HiveField(9)
  final String? zipCode;

  @HiveField(10)
  final String? phone;

  @HiveField(11)
  final String? email;

  @HiveField(12)
  final String? website;

  @HiveField(13)
  final String? logo;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    this.legalName,
    this.ein,
    this.mcNumber,
    this.dotNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) => _$CompanyFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        legalName,
        mcNumber,
        dotNumber,
        email,
      ];

  Company copyWith({
    String? id,
    String? name,
    String? legalName,
    String? ein,
    String? mcNumber,
    String? dotNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? website,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      ein: ein ?? this.ein,
      mcNumber: mcNumber ?? this.mcNumber,
      dotNumber: dotNumber ?? this.dotNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
