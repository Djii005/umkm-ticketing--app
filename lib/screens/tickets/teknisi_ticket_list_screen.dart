import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';

/// Daftar tiket yang ditugaskan kepada teknisi yang sedang login.
/// [historyOnly] menampilkan hanya tiket yang sudah selesai/ditutup (Riwayat Pekerjaan).
class TeknisiTicketListScreen extends ConsumerStatefulWidget {
  final bool historyOnly;

  const TeknisiTicketListScreen({super.key, this.historyOnly = false});

  @override
  ConsumerState<TeknisiTicketListScreen> createState() => _TeknisiTicketListScreenState();
}

class _TeknisiTicketListScreenState extends ConsumerState<TeknisiTicketListScreen> {
  String _statusFilter = 'all';

  static const _statusOptions = {
    'all': 'Semua Status',
    'assigned': 'Baru Ditugaskan',
    'in_progress': 'Dalam Proses',
    'pending_parts': 'Menunggu Sparepart',
    'resolved': 'Selesai',
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Anda belum login.')));
    }

    final ticketsAsync = ref.watch(ticketsForTechnicianProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          widget.historyOnly ? 'Riwayat Pekerjaan' : 'Tiket Ditugaskan',
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (!widget.historyOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    items: _statusOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(ticketsForTechnicianProvider(user.id).future),
              child: ticketsAsync.when(
                data: (tickets) {
                  final filtered = tickets.where((t) {
                    if (widget.historyOnly) {
                      return t.status == 'resolved' || t.status == 'closed';
                    }
                    if (t.status == 'resolved' || t.status == 'closed') return false;
                    return _statusFilter == 'all' || t.status == _statusFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          widget.historyOnly ? 'Belum ada riwayat pekerjaan.' : 'Belum ada tiket yang ditugaskan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) => _TeknisiTicketCard(ticket: filtered[index]),
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
}

class _TeknisiTicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _TeknisiTicketCard({required this.ticket});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(ticket.priority);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ticket.ticketNumber ?? 'TKT-PENDING', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(ticket.priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ticket.title, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(ticket.hospital?.name ?? 'Rumah Sakit', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
