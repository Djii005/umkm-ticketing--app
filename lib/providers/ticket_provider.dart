import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticket_model.dart';
import '../models/hospital_model.dart';
import '../models/equipment_model.dart';
import '../services/ticket_service.dart';
import '../services/hospital_service.dart';
import '../services/equipment_service.dart';

// Service Providers
final ticketServiceProvider = Provider<TicketService>((ref) {
  return TicketService();
});

final hospitalServiceProvider = Provider<HospitalService>((ref) {
  return HospitalService();
});

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  return EquipmentService();
});

// FutureProvider for fetching all tickets
final ticketsListProvider = FutureProvider<List<TicketModel>>((ref) async {
  return ref.watch(ticketServiceProvider).getTickets();
});

// FutureProvider for fetching a single ticket by ID
final ticketDetailProvider = FutureProvider.family<TicketModel, String>((ref, ticketId) async {
  return ref.watch(ticketServiceProvider).getTicketById(ticketId);
});

// StreamProvider for realtime ticket updates
final ticketStreamProvider = StreamProvider<List<TicketModel>>((ref) {
  return ref.watch(ticketServiceProvider).streamTickets();
});

// FutureProvider for fetching all hospitals (useful in creation form)
final hospitalsListProvider = FutureProvider<List<HospitalModel>>((ref) async {
  return ref.watch(hospitalServiceProvider).getHospitals();
});

// FutureProvider for fetching equipment under a hospital
final equipmentListProvider = FutureProvider.family<List<EquipmentModel>, String>((ref, hospitalId) async {
  if (hospitalId.isEmpty) return [];
  return ref.watch(equipmentServiceProvider).getEquipmentForHospital(hospitalId);
});

// StateNotifier to manage ticket operations (Create/Update status)
class TicketOpsNotifier extends StateNotifier<AsyncValue<void>> {
  final TicketService _ticketService;

  TicketOpsNotifier(this._ticketService) : super(const AsyncValue.data(null));

  Future<bool> createTicket({
    required String title,
    required String description,
    required String hospitalId,
    required String equipmentId,
    required String priority,
    required String serviceType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ticketService.createTicket(
        title: title,
        description: description,
        hospitalId: hospitalId,
        equipmentId: equipmentId,
        priority: priority,
        serviceType: serviceType,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    state = const AsyncValue.loading();
    try {
      await _ticketService.updateTicketStatus(ticketId, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final ticketOpsNotifierProvider = StateNotifierProvider<TicketOpsNotifier, AsyncValue<void>>((ref) {
  return TicketOpsNotifier(ref.watch(ticketServiceProvider));
});
