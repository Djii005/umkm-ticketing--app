class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? contactPerson;
  final String? phone;
  final DateTime? createdAt;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.contactPerson,
    this.phone,
    this.createdAt,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'address': address,
      'city': city,
      'contact_person': contactPerson,
      'phone': phone,
    };
  }
}
