// ============================================================================
// 👤 PROFILE SERVICE — Handles fetching and updating user profile data.
// HOW TO SWITCH: Uncomment "🔜 SUPABASE VERSION", delete "🟢 DUMMY VERSION"
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProfileService {
  // ── GET PROFILE — Fetch the user's full profile from the database ──
  Future<Map<String, dynamic>> getProfile(String userId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return {};
    }
  }

  // ── UPDATE PROFILE — Save changes to the user's profile ──
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? course,
    String? yearLevel,
    String? address,
    String? contactNumber,
  }) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      // Build the update map — only include fields that were provided
      final Map<String, dynamic> updates = {};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (course != null) updates['course'] = course;
      if (yearLevel != null) updates['year_level'] = yearLevel;
      if (address != null) updates['address'] = address;
      if (contactNumber != null) updates['contact_number'] = contactNumber;

      await supabase.from('users').update(updates).eq('id', userId);
      return {'success': true, 'message': 'Profile updated!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
