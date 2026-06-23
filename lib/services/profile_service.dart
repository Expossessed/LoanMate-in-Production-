import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProfileService {
  //get the profile from the database
  Future<Map<String, dynamic>> getProfile(String userId) async {
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

  //update profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? course,
    String? yearLevel,
    String? address,
    String? contactNumber,
  }) async {
    try {
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
