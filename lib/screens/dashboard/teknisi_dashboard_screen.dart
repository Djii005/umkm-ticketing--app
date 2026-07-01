import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class TeknisiDashboardScreen extends ConsumerWidget {
  const TeknisiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final AsyncValue<List<TicketModel>> ticketsAsync = user == null
        ? const AsyncValue<List<TicketModel>>.data(<TicketModel>[])
        : ref.watch(ticketsForTechnicianProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.build_rounded, color: Colors.teal.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dashboard Teknisi',
              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref.refresh(ticketsForTechnicianProvider(user.id).future);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => Text(
                  'Halo, ${profile?.fullName ?? 'Teknisi'} 🔧',
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                loading: () => const SizedBox(height: 24),
                error: (_, __) => const Text('Halo, Teknisi 🔧'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Berikut ringkasan tugas servis yang ditugaskan kepada Anda.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),

              const Text(
                'Ringkasan Tugas',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ticketsAsync.when(
                data: (tickets) {
                  final newTickets = tickets.where((t) => t.status == 'assigned').length;
                  final inProgress = tickets.where((t) => t.status == 'in_progress' || t.status == 'pending_parts').length;
                  final doneToday = tickets.where((t) {
                    if (t.status != 'resolved' && t.status != 'closed') return false;
                    if (t.resolvedAt == null) return false;
                    final now = DateTime.now();
                    return t.resolvedAt!.year == now.year && t.resolvedAt!.month == now.month && t.resolvedAt!.day == now.day;
                  }).length;

                  return Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Tiket Baru', value: '$newTickets', color: Colors.blue, icon: Icons.fiber_new_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Proses', value: '$inProgress', color: Colors.orange, icon: Icons.sync_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Selesai Hari Ini', value: '$doneToday', color: Colors.green, icon: Icons.check_circle_rounded)),
                    ],
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, _) => Center(child: Text('Gagal memuat statistik: $err')),
              ),

              const SizedBox(height: 28),
              const Text(
                'Menu',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _MenuCard(
                      title: 'Daftar Tiket',
                      subtitle: 'Tiket yang ditugaskan',
                      icon: Icons.assignment_rounded,
                      gradientColors: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      onTap: () => context.push('/teknisi/tickets'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MenuCard(
                      title: 'Riwayat Pekerjaan',
                      subtitle: 'Tiket yang pernah ditangani',
                      icon: Icons.history_rounded,
                      gradientColors: const [Color(0xFF64748B), Color(0xFF475569)],
                      onTap: () => context.push('/teknisi/history'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
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
