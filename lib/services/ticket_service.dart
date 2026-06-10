import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/ticket_model.dart';

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
    await _supabase.from('tickets').update({
      'status': status,
    }).eq('id', ticketId);
    
    // Log the change
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await _supabase.from('ticket_logs').insert({
        'ticket_id': ticketId,
        'user_id': currentUserId,
        'action': 'Status updated to $status',
      });
    }
  }
}
