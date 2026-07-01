import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Laporan Tiket', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          final now = DateTime.now();
          final daily = tickets.where((t) => t.createdAt != null && _isSameDay(t.createdAt!, now)).toList();
          final monthly = tickets.where((t) => t.createdAt != null && t.createdAt!.year == now.year && t.createdAt!.month == now.month).toList();
          final yearly = tickets.where((t) => t.createdAt != null && t.createdAt!.year == now.year).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan periode laporan berdasarkan seluruh tiket yang tercatat di sistem.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 20),
                _ReportCard(title: 'Laporan Harian', subtitle: 'Tiket hari ini', tickets: daily, color: Colors.blue),
                const SizedBox(height: 16),
                _ReportCard(title: 'Laporan Bulanan', subtitle: 'Tiket bulan ini', tickets: monthly, color: Colors.orange),
                const SizedBox(height: 16),
                _ReportCard(title: 'Laporan Tahunan', subtitle: 'Tiket tahun ini', tickets: yearly, color: Colors.green),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ekspor PDF/Excel dapat dikembangkan pada tahap berikutnya bersama integrasi backend laporan.',
                          style: TextStyle(color: Color(0xFF78350F), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat laporan: $err')),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<TicketModel> tickets;
  final Color color;

  const _ReportCard({required this.title, required this.subtitle, required this.tickets, required this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.bar_chart_rounded, color: color)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${tickets.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
              Text('$resolved selesai', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
