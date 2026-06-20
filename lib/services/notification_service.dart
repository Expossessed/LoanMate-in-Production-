// ============================================================================
// 🔔 NOTIFICATION SERVICE — Handles fetching notifications for the user.
// HOW TO SWITCH: Uncomment "🔜 SUPABASE VERSION", delete "🟢 DUMMY VERSION"
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class NotificationService {
  // ── GET NOTIFICATIONS — Fetch all notifications for a user ──
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // ── MARK AS READ — Mark a single notification as read ──
  Future<void> markAsRead(String notificationId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // ── MARK ALL AS READ — Mark all notifications for a user as read ──
  Future<void> markAllAsRead(String userId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}
