// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 0;

  @override
  Company read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Company(
      id: fields[0] as String,
      name: fields[1] as String,
      legalName: fields[2] as String?,
      ein: fields[3] as String?,
      mcNumber: fields[4] as String?,
      dotNumber: fields[5] as String?,
      address: fields[6] as String?,
      city: fields[7] as String?,
      state: fields[8] as String?,
      zipCode: fields[9] as String?,
      phone: fields[10] as String?,
      email: fields[11] as String?,
      website: fields[12] as String?,
      logo: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.legalName)
      ..writeByte(3)
      ..write(obj.ein)
      ..writeByte(4)
      ..write(obj.mcNumber)
      ..writeByte(5)
      ..write(obj.dotNumber)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.city)
      ..writeByte(8)
      ..write(obj.state)
      ..writeByte(9)
      ..write(obj.zipCode)
      ..writeByte(10)
      ..write(obj.phone)
      ..writeByte(11)
      ..write(obj.email)
      ..writeByte(12)
      ..write(obj.website)
      ..writeByte(13)
      ..write(obj.logo)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Company _$CompanyFromJson(Map<String, dynamic> json) => Company(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legalName'] as String?,
      ein: json['ein'] as String?,
      mcNumber: json['mcNumber'] as String?,
      dotNumber: json['dotNumber'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logo: json['logo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CompanyToJson(Company instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'legalName': instance.legalName,
      'ein': instance.ein,
      'mcNumber': instance.mcNumber,
      'dotNumber': instance.dotNumber,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'logo': instance.logo,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
