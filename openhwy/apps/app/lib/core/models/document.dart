import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'document.g.dart';

enum DocumentType {
  @JsonValue('license')
  license,
  @JsonValue('insurance')
  insurance,
  @JsonValue('bill')
  bill,
  @JsonValue('inspection')
  inspection,
  @JsonValue('hazmat')
  hazmat,
  @JsonValue('delivery')
  delivery,
  @JsonValue('rate_confirmation')
  rateConfirmation,
  @JsonValue('pod')
  pod,
  @JsonValue('bol')
  bol,
  @JsonValue('other')
  other,
}

enum DocumentStatus {
  @JsonValue('verified')
  verified,
  @JsonValue('pending')
  pending,
  @JsonValue('expired')
  expired,
  @JsonValue('rejected')
  rejected,
}

@JsonSerializable()
class Document extends Equatable {
  final String id;
  final String name;
  final DocumentType type;
  final String category;
  final DocumentStatus status;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @JsonKey(name: 'load_id')
  final String? loadId;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'file_size')
  final int fileSize;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.status,
    this.driverId,
    this.driverName,
    this.loadId,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.expiresAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiry = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        status,
        fileUrl,
        uploadedAt,
      ];

  Document copyWith({
    String? id,
    String? name,
    DocumentType? type,
    String? category,
    DocumentStatus? status,
    String? driverId,
    String? driverName,
    String? loadId,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedAt,
    DateTime? expiresAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      loadId: loadId ?? this.loadId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
