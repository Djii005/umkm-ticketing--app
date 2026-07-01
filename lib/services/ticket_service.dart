import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/ticket_model.dart';
import '../models/ticket_log_model.dart';

class TicketService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Stream of tickets (for realtime)
  Stream<List<TicketModel>> streamTickets() {
    return _supabase
        .from('tickets')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.map((map) => TicketModel.fromJson(map)).toList());
  }

  // Fetch all tickets with joins
  Future<List<TicketModel>> getTickets() async {
    final response = await _supabase
        .from('tickets')
        .select('*, hospitals(*), equipment(*)');
    
    return (response as List).map((json) => TicketModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Fetch tickets assigned to a specific technician
  Future<List<TicketModel>> getTicketsForTechnician(String technicianId) async {
    final response = await _supabase
        .from('tickets')
        .select('*, hospitals(*), equipment(*)')
        .eq('technician_id', technicianId);

    return (response as List).map((json) => TicketModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Fetch ticket by ID
  Future<TicketModel> getTicketById(String id) async {
    final response = await _supabase
        .from('tickets')
        .select('*, hospitals(*), equipment(*)')
        .eq('id', id)
        .single();
    
    return TicketModel.fromJson(response);
  }

  // Create ticket
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String hospitalId,
    required String equipmentId,
    required String priority,
    required String serviceType,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not logged in');

    final response = await _supabase.from('tickets').insert({
      'customer_id': currentUserId,
      'hospital_id': hospitalId,
      'equipment_id': equipmentId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'open',
      'service_type': serviceType,
    }).select('*, hospitals(*), equipment(*)').single();

    return TicketModel.fromJson(response);
  }

  // Update Ticket Status
  Future<void> updateTicketStatus(String ticketId, String status) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'resolved' || status == 'closed') {
      updateData['resolved_at'] = DateTime.now().toIso8601String();
    }

    await _supabase.from('tickets').update(updateData).eq('id', ticketId);

    // Log the change
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await _supabase.from('ticket_logs').insert({
        'ticket_id': ticketId,
        'user_id': currentUserId,
        'action': 'Status diperbarui menjadi $status',
      });
    }
  }

  // Assign a technician to a ticket (used by admin)
  Future<void> assignTechnician(String ticketId, String technicianId) async {
    await _supabase.from('tickets').update({
      'technician_id': technicianId,
      'status': 'assigned',
    }).eq('id', ticketId);

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await _supabase.from('ticket_logs').insert({
        'ticket_id': ticketId,
        'user_id': currentUserId,
        'action': 'Teknisi ditugaskan',
      });
    }
  }

  // Fetch handling history (logs) for a ticket
  Future<List<TicketLogModel>> getTicketLogs(String ticketId) async {
    final response = await _supabase
        .from('ticket_logs')
        .select('*, users(full_name, role)')
        .eq('ticket_id', ticketId)
        .order('created_at');

    return (response as List)
        .map((json) => TicketLogModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Add a work note (used by technician while handling a ticket)
  Future<void> addTicketNote(String ticketId, String note) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not logged in');

    await _supabase.from('ticket_logs').insert({
      'ticket_id': ticketId,
      'user_id': currentUserId,
      'action': 'Catatan pekerjaan ditambahkan',
      'notes': note,
    });
  }
}
