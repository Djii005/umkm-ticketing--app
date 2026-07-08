import 'hospital_model.dart';
import 'equipment_model.dart';

class TicketModel {
  final String id;
  final String? ticketNumber;
  final String customerId;
  final String hospitalId;
  final String equipmentId;
  final String? technicianId;
  final String title;
  final String description;
  final String priority; 
  final String status;   
  final String serviceType; 
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  final HospitalModel? hospital;
  final EquipmentModel? equipment;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? technician;

  TicketModel({
    required this.id,
    this.ticketNumber,
    required this.customerId,
    required this.hospitalId,
    required this.equipmentId,
    this.technicianId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.serviceType,
    this.createdAt,
    this.resolvedAt,
    this.hospital,
    this.equipment,
    this.customer,
    this.technician,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String?,
      customerId: json['customer_id'] as String,
      hospitalId: json['hospital_id'] as String,
      equipmentId: json['equipment_id'] as String,
      technicianId: json['technician_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      serviceType: json['service_type'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      hospital: json['hospitals'] != null ? HospitalModel.fromJson(json['hospitals'] as Map<String, dynamic>) : null,
      equipment: json['equipment'] != null ? EquipmentModel.fromJson(json['equipment'] as Map<String, dynamic>) : null,
      customer: json['customer'] as Map<String, dynamic>?,
      technician: json['technician'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'customer_id': customerId,
      'hospital_id': hospitalId,
      'equipment_id': equipmentId,
      'technician_id': technicianId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'service_type': serviceType,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
