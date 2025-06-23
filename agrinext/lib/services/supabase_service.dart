import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Sign up user
  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  // Login user
  Future<AuthResponse> login(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  // Save user profile to 'profiles' table
  Future<void> saveUserProfile({
    required String id,
    required String username,
    required String email,
    required String birthdate,
    required String gender,
    required String? avatarUrl,
  }) async {
    await client.from('profiles').insert({
      'id': id,
      'username': username,
      'email': email,
      'birthdate': birthdate,
      'gender': gender,
      'avatar_url': avatarUrl,
    });
  }

  // Upload profile picture to Supabase Storage
  Future<String> uploadProfilePicture(String userId, Uint8List fileBytes, String fileExt) async {
    final filePath = 'avatars/$userId$fileExt';

    await client.storage
        .from('profile_pictures')
        .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(upsert: true));

    return client.storage.from('profile_pictures').getPublicUrl(filePath);
  }

  // Get user profile by user ID
  Future<Map<String, dynamic>> getUserProfile(String id) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return data;
  }

  // Logout user
  Future<void> logout() async {
    await client.auth.signOut();
  }
}
