import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final ticketsAsync = ref.watch(ticketsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.indigo.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dashboard Admin',
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
        onRefresh: () => ref.refresh(ticketsListProvider.future),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.when(
                    data: (profile) => Text(
                      'Halo, ${profile?.fullName ?? 'Admin'} 👋',
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    loading: () => const SizedBox(height: 24),
                    error: (_, __) => const Text('Halo, Admin 👋'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pantau seluruh tiket servis alat kesehatan di sini.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Ringkasan Tiket',
                    style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ticketsAsync.when(
                    data: (tickets) {
                      final open = tickets.where((t) => t.status == 'open').length;
                      final progress = tickets
                          .where((t) => t.status == 'assigned' || t.status == 'in_progress' || t.status == 'pending_parts')
                          .length;
                      final done = tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;
                      final overdue = tickets.where((t) {
                        if (t.status == 'resolved' || t.status == 'closed') return false;
                        if (t.createdAt == null) return false;
                        return DateTime.now().difference(t.createdAt!).inDays >= 2;
                      }).length;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.8,
                        children: [
                          _StatCard(title: 'Tiket Terbuka', value: '$open', color: Colors.blue, icon: Icons.fiber_new_rounded),
                          _StatCard(title: 'Dalam Proses', value: '$progress', color: Colors.orange, icon: Icons.sync_rounded),
                          _StatCard(title: 'Selesai', value: '$done', color: Colors.green, icon: Icons.check_circle_rounded),
                          _StatCard(title: 'Terlambat', value: '$overdue', color: Colors.red, icon: Icons.warning_amber_rounded),
                        ],
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                    error: (err, _) => Center(child: Text('Gagal memuat statistik: $err')),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Menu Manajemen',
                    style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    children: [
                      _MenuCard(
                        title: 'Manajemen Tiket',
                        subtitle: 'Assign teknisi & ubah status',
                        icon: Icons.confirmation_number_rounded,
                        gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        onTap: () => context.push('/admin/tickets'),
                      ),
                      _MenuCard(
                        title: 'Manajemen Pengguna',
                        subtitle: 'Data pengguna & teknisi',
                        icon: Icons.people_alt_rounded,
                        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                        onTap: () => context.push('/admin/users'),
                      ),
                      _MenuCard(
                        title: 'Manajemen Rumah Sakit',
                        subtitle: 'Kelola rumah sakit & alat',
                        icon: Icons.local_hospital_rounded,
                        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                        onTap: () => context.push('/admin/hospitals'),
                      ),
                      _MenuCard(
                        title: 'Laporan',
                        subtitle: 'Harian, bulanan, tahunan',
                        icon: Icons.bar_chart_rounded,
                        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        onTap: () => context.push('/admin/reports'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w900)),
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 9)),
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
