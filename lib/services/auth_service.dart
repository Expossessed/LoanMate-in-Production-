import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  String toEmail(String studentId) => '$studentId@loanmate.local';

  Future<Map<String, dynamic>> signUp({
    required String studentId,
    required String password,
    required String firstName,
    required String lastName,
    required String course,
    required String yearLevel,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: toEmail(studentId),
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        await supabase.from('users').insert({
          'id': userId,
          'student_id': studentId,
          'first_name': firstName,
          'last_name': lastName,
          'course': course,
          'year_level': yearLevel,
          'enrollment_status': 'active',
          'role': 'student',
          'agreed_to_terms': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        final walletRow = await supabase
            .from('wallet')
            .insert({
              'user_id': userId,
              'balance': 0.0,
              'savings_goal': 0.0,
              'current_savings': 0.0,
            })
            .select('id')
            .single();
        final walletId = walletRow['id'] as String;

        final loanRow = await supabase
            .from('loans')
            .insert({
              'user_id': userId,
              'amount': 0.0,
              'purpose': 'placeholder',
              'status': 'pending',
              'applied_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        final loanId = loanRow['id'] as String;

        await supabase.from('repayment_schedule').insert({
          'loan_id': loanId,
          'due_date': DateTime.now().toIso8601String().substring(0, 10),
          'amount': 0.0,
          'status': 'pending',
        });

        await supabase.from('documents').insert({
          'user_id': userId,
          'loan_id': loanId,
          'file_url': '',
          'uploaded_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'welcome',
          'message': 'Welcome to LoanMate!',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('transactions').insert({
          'wallet_id': walletId,
          'type': 'init',
          'amount': 0.0,
          'date': DateTime.now().toIso8601String(),
          'description': 'Account created',
        });

        return {'success': true, 'message': 'Registration successful!'};
      } else {
        return {'success': false, 'message': 'Sign up failed. Try again.'};
      }
    } on AuthException catch (e) {
      // Give user-friendly error messages instead of raw Supabase errors
      if (e.message.contains('rate limit') || e.statusCode == '429') {
        return {
          'success': false,
          'message': 'Too many attempts. Please wait a minute and try again.',
        };
      }
      if (e.message.contains('already registered') ||
          e.message.contains('already been registered')) {
        return {
          'success': false,
          'message': 'This Student ID is already registered. Try logging in.',
        };
      }
      return {'success': false, 'message': 'Auth error: ${e.message}'};
    } on PostgrestException catch (e) {
      // A table insert failed — log the real Postgres error for debugging.
      debugPrint('Registration DB insert failed:');
      debugPrint('  code   : ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  details: ${e.details}');
      return {
        'success': false,
        'message': 'DB error [${e.code}]: ${e.message}',
      };
    } catch (e) {
      debugPrint('Registration unexpected error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── SIGN IN ──
  Future<Map<String, dynamic>> signIn({
    required String studentId,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: toEmail(studentId),
        password: password,
      );

      if (response.user != null) {
        return {'success': true, 'message': 'Login successful!'};
      } else {
        return {'success': false, 'message': 'Invalid credentials.'};
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login')) {
        return {'success': false, 'message': 'Wrong Student ID or password.'};
      }
      return {'success': false, 'message': 'Login error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── SIGN OUT ──
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ── GET CURRENT USER ──
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }
}
