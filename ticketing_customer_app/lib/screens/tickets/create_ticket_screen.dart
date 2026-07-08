import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedHospitalId;
  String? _selectedEquipmentId;
  String _selectedPriority = 'medium';
  String _selectedServiceType = 'repair';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHospitalId == null || _selectedEquipmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih Rumah Sakit dan Alat terlebih dahulu')),
        );
        return;
      }

      final success = await ref.read(ticketOpsNotifierProvider.notifier).createTicket(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        hospitalId: _selectedHospitalId!,
        equipmentId: _selectedEquipmentId!,
        priority: _selectedPriority,
        serviceType: _selectedServiceType,
      );

      if (success && mounted) {
        // Refresh ticket list
        ref.invalidate(ticketsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsListProvider);
    final equipmentAsync = _selectedHospitalId != null
        ? ref.watch(equipmentListProvider(_selectedHospitalId!))
        : null;
    final opsState = ref.watch(ticketOpsNotifierProvider);

    // Listen to operation errors
    ref.listen<AsyncValue>(ticketOpsNotifierProvider, (_, state) {
      if (!state.isLoading && state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Buat Tiket Baru',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Laporan',
                  hintText: 'Contoh: Inkubator tidak memanas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  fillColor: Colors.white,
                  filled: true,
                ),
                validator: (value) => value!.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kerusakan',
                  hintText: 'Jelaskan sedetail mungkin masalah alat...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  fillColor: Colors.white,
                  filled: true,
                ),
                validator: (value) => value!.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Dropdown Hospital
              hospitalsAsync.when(
                data: (hospitals) {
                  if (hospitals.isEmpty) {
                    return _buildWarningBox('Data Rumah Sakit kosong di Supabase. Harap isi data terlebih dahulu.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedHospitalId,
                    decoration: const InputDecoration(
                      labelText: 'Rumah Sakit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    items: hospitals.map((h) {
                      return DropdownMenuItem(value: h.id, child: Text(h.name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHospitalId = value;
                        _selectedEquipmentId = null; // reset equipment
                      });
                    },
                    validator: (value) => value == null ? 'Pilih rumah sakit' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error memuat RS: $err'),
              ),
              const SizedBox(height: 16),

              // Dropdown Equipment (depends on selected Hospital)
              if (_selectedHospitalId != null && equipmentAsync != null)
                equipmentAsync.when(
                  data: (equipment) {
                    if (equipment.isEmpty) {
                      return _buildWarningBox('Tidak ada alat medis di Rumah Sakit ini.');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedEquipmentId,
                      decoration: const InputDecoration(
                        labelText: 'Alat Medis',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      items: equipment.map((e) {
                        return DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.brand})'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipmentId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Pilih alat medis' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error memuat alat: $err'),
                ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Prioritas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  fillColor: Colors.white,
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low (Rendah)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium (Sedang)')),
                  DropdownMenuItem(value: 'high', child: Text('High (Tinggi)')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent (Darurat)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Service Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Layanan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  fillColor: Colors.white,
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'repair', child: Text('Perbaikan (Repair)')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Perawatan (Maintenance)')),
                  DropdownMenuItem(value: 'calibration', child: Text('Kalibrasi (Calibration)')),
                  DropdownMenuItem(value: 'installation', child: Text('Instalasi (Installation)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: opsState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: opsState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Laporan Tiket',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
