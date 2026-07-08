import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<EquipmentModel>> getEquipmentForHospital(String hospitalId) async {
    final response = await _supabase
        .from('equipment')
        .select('*, hospitals(*)')
        .eq('hospital_id', hospitalId)
        .order('name');
    return (response as List).map((json) => EquipmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<EquipmentModel> createEquipment(EquipmentModel equipment) async {
    final response = await _supabase
        .from('equipment')
        .insert(equipment.toJson())
        .select('*, hospitals(*)')
        .single();
    return EquipmentModel.fromJson(response);
  }
}
