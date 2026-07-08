import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/hospital_model.dart';

class HospitalService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<List<HospitalModel>> getHospitals() async {
    final response = await _supabase.from('hospitals').select().order('name');
    return (response as List).map((json) => HospitalModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<HospitalModel> createHospital(HospitalModel hospital) async {
    final response = await _supabase
        .from('hospitals')
        .insert(hospital.toJson())
        .select()
        .single();
    return HospitalModel.fromJson(response);
  }
}
