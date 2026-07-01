import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';

class AdminTicketListScreen extends ConsumerStatefulWidget {
  const AdminTicketListScreen({super.key});

  @override
  ConsumerState<AdminTicketListScreen> createState() => _AdminTicketListScreenState();
}

class _AdminTicketListScreenState extends ConsumerState<AdminTicketListScreen> {
  String _statusFilter = 'all';
  String _priorityFilter = 'all';

  static const _statusOptions = {
    'all': 'Semua Status',
    'open': 'Baru',
    'assigned': 'Teknisi Ditunjuk',
    'in_progress': 'Proses',
    'pending_parts': 'Pending Sparepart',
    'resolved': 'Selesai',
    'closed': 'Ditutup',
  };

  static const _priorityOptions = {
    'all': 'Semua Prioritas',
    'low': 'Rendah',
    'medium': 'Sedang',
    'high': 'Tinggi',
    'urgent': 'Mendesak',
  };

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Manajemen Tiket', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildFilterDropdown(_statusOptions, _statusFilter, (v) => setState(() => _statusFilter = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildFilterDropdown(_priorityOptions, _priorityFilter, (v) => setState(() => _priorityFilter = v!))),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(ticketsListProvider.future),
              child: ticketsAsync.when(
                data: (tickets) {
                  final filtered = tickets.where((t) {
                    final statusOk = _statusFilter == 'all' || t.status == _statusFilter;
                    final priorityOk = _priorityFilter == 'all' || t.priority == _priorityFilter;
                    return statusOk && priorityOk;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Tidak ada tiket yang cocok dengan filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) => _AdminTicketCard(ticket: filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Gagal memuat tiket: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(Map<String, String> options, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _AdminTicketCard({required this.ticket});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'pending_parts':
        return Colors.red;
      case 'resolved':
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/tickets/${ticket.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 48,
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.ticketNumber ?? 'TKT-PENDING', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        ticket.technicianId == null ? 'Belum ada teknisi' : 'Sudah ditugaskan',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
