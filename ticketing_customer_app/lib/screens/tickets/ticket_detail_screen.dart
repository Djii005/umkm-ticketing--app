import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

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

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'BARU (OPEN)';
      case 'assigned':
        return 'TEKNISI DITUNJUK';
      case 'in_progress':
        return 'PROSES (IN PROGRESS)';
      case 'pending_parts':
        return 'PENDING PART';
      case 'resolved':
        return 'SELESAI (RESOLVED)';
      case 'closed':
        return 'DITUTUP (CLOSED)';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final opsState = ref.watch(ticketOpsNotifierProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final role = profileAsync.valueOrNull?.role ?? 'customer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Detail Tiket Servis',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ticketDetailProvider(ticketId).future),
        child: ticketAsync.when(
          data: (ticket) {
            final statusColor = _getStatusColor(ticket.status);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Information Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.ticketNumber ?? 'TKT-PENDING',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(ticket.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.description,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Hospital & Equipment Information Card
                  _buildSectionHeader('Informasi Pelanggan & Alat'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.local_hospital_rounded, 'Rumah Sakit', ticket.hospital?.name ?? '-'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(Icons.location_on_rounded, 'Alamat', ticket.hospital?.address ?? '-'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(Icons.settings_suggest_rounded, 'Alat Kesehatan', ticket.equipment?.name ?? '-'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(Icons.qr_code_scanner_rounded, 'Serial Number', ticket.equipment?.serialNumber ?? '-'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Action Section for Status Updates (role-aware)
                  if (role == 'admin') ...[
                    _buildSectionHeader('Assign Teknisi'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final techniciansAsync = ref.watch(techniciansListProvider);
                          return techniciansAsync.when(
                            data: (technicians) => DropdownButtonFormField<String>(
                              initialValue: ticket.technicianId,
                              decoration: const InputDecoration(
                                hintText: 'Pilih teknisi',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                fillColor: Color(0xFFF8FAFC),
                                filled: true,
                              ),
                              items: technicians
                                  .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName)))
                                  .toList(),
                              onChanged: opsState.isLoading
                                  ? null
                                  : (technicianId) async {
                                      if (technicianId != null) {
                                        await ref
                                            .read(ticketOpsNotifierProvider.notifier)
                                            .assignTechnician(ticket.id, technicianId);
                                        ref.invalidate(ticketDetailProvider(ticketId));
                                        ref.invalidate(ticketsListProvider);
                                      }
                                    },
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => Text('Gagal memuat daftar teknisi: $err'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (role == 'admin' || role == 'teknisi') ...[
                    _buildSectionHeader('Ubah Status Tiket'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Pilih status terbaru untuk memperbarui progres penanganan:',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: ticket.status,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              fillColor: Color(0xFFF8FAFC),
                              filled: true,
                            ),
                            items: role == 'admin'
                                ? const [
                                    DropdownMenuItem(value: 'open', child: Text('Baru (Open)')),
                                    DropdownMenuItem(value: 'assigned', child: Text('Teknisi Ditunjuk')),
                                    DropdownMenuItem(value: 'in_progress', child: Text('Proses (In Progress)')),
                                    DropdownMenuItem(value: 'pending_parts', child: Text('Pending Sparepart')),
                                    DropdownMenuItem(value: 'resolved', child: Text('Selesai (Resolved)')),
                                    DropdownMenuItem(value: 'closed', child: Text('Ditutup (Closed)')),
                                  ]
                                : const [
                                    // Teknisi hanya dapat menerima & memproses tiket yang ditugaskan
                                    DropdownMenuItem(value: 'assigned', child: Text('Baru Ditugaskan')),
                                    DropdownMenuItem(value: 'in_progress', child: Text('Dalam Proses')),
                                    DropdownMenuItem(value: 'pending_parts', child: Text('Menunggu Sparepart')),
                                    DropdownMenuItem(value: 'resolved', child: Text('Selesai')),
                                  ],
                            onChanged: opsState.isLoading
                                ? null
                                : (newStatus) async {
                                    if (newStatus != null && newStatus != ticket.status) {
                                      await ref
                                          .read(ticketOpsNotifierProvider.notifier)
                                          .updateTicketStatus(ticket.id, newStatus);
                                      // Refresh details and summary list
                                      ref.invalidate(ticketDetailProvider(ticketId));
                                      ref.invalidate(ticketsListProvider);
                                    }
                                  },
                          ),
                          if (opsState.isLoading) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (role == 'teknisi') ...[
                    _buildSectionHeader('Tambah Catatan Pekerjaan'),
                    const SizedBox(height: 8),
                    _TechnicianNoteForm(ticketId: ticketId),
                    const SizedBox(height: 20),
                  ],

                  // 4. Handling history (Riwayat Penanganan) - visible to all roles
                  _buildSectionHeader('Riwayat Penanganan'),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final logsAsync = ref.watch(ticketLogsProvider(ticketId));
                      return logsAsync.when(
                        data: (logs) {
                          if (logs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Text('Belum ada riwayat penanganan.', style: TextStyle(color: Color(0xFF64748B))),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: logs.map((log) {
                                return Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
                                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(log.notes!, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        log.createdAt != null
                                            ? '${log.createdAt!.day}/${log.createdAt!.month}/${log.createdAt!.year} ${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}'
                                            : '-',
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                        error: (err, _) => Text('Gagal memuat riwayat: $err'),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat detail tiket: $err')),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechnicianNoteForm extends ConsumerStatefulWidget {
  final String ticketId;

  const _TechnicianNoteForm({required this.ticketId});

  @override
  ConsumerState<_TechnicianNoteForm> createState() => _TechnicianNoteFormState();
}

class _TechnicianNoteFormState extends ConsumerState<_TechnicianNoteForm> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    final ok = await ref.read(ticketOpsNotifierProvider.notifier).addTicketNote(widget.ticketId, note);
    if (ok) {
      _noteController.clear();
      ref.invalidate(ticketLogsProvider(widget.ticketId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final opsState = ref.watch(ticketOpsNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan pekerjaan (mis. hasil pemeriksaan, sparepart yang dipakai)...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: opsState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan Catatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
