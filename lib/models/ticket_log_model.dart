class TicketLogModel {
  final String id;
  final String ticketId;
  final String userId;
  final String action;
  final String? notes;
  final DateTime? createdAt;
  final Map<String, dynamic>? user;

  TicketLogModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.action,
    this.notes,
    this.createdAt,
    this.user,
  });

  factory TicketLogModel.fromJson(Map<String, dynamic> json) {
    return TicketLogModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      user: json['users'] as Map<String, dynamic>?,
    );
  }
}
