import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get profile (role, name, etc) for the given auth user id
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // Get all users with a given role (e.g. 'teknisi')
  Future<List<UserModel>> getUsersByRole(String role) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('role', role)
        .order('full_name');

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get all users (for admin management screens)
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase.from('users').select().order('full_name');

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Update the password of the currently logged in user
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
