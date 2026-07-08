import 'hospital_model.dart';

class EquipmentModel {
  final String id;
  final String hospitalId;
  final String name;
  final String brand;
  final String model;
  final String serialNumber;
  final String category;
  final DateTime? installationDate;
  final DateTime? warrantyExpiry;
  final DateTime? createdAt;
  final HospitalModel? hospital;

  EquipmentModel({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.category,
    this.installationDate,
    this.warrantyExpiry,
    this.createdAt,
    this.hospital,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] as String,
      hospitalId: json['hospital_id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      serialNumber: json['serial_number'] as String,
      category: json['category'] as String,
      installationDate: json['installation_date'] != null ? DateTime.parse(json['installation_date'] as String) : null,
      warrantyExpiry: json['warranty_expiry'] != null ? DateTime.parse(json['warranty_expiry'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      hospital: json['hospitals'] != null ? HospitalModel.fromJson(json['hospitals'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'hospital_id': hospitalId,
      'name': name,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'category': category,
      'installation_date': installationDate?.toIso8601String(),
      'warranty_expiry': warrantyExpiry?.toIso8601String(),
    };
  }
}
