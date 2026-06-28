import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ── Constants ──────────────────────────────────────────────────────────────
const int _kMaxAttempts = 5;
const Duration _kLockoutDuration = Duration(minutes: 5);

class AuthService {
  String toEmail(String studentId) => '$studentId@loanmate.local';

  // ── SIGN UP ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signUp({
    required String studentId,
    required String password,
    required String firstName,
    required String lastName,
    required String course,
    required String yearLevel,
    File? studyLoadImage,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: toEmail(studentId),
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // ── 1. users FIRST — all other tables FK-reference this row ──────
        await supabase.from('users').insert({
          'id': userId,
          'student_id': studentId,
          'first_name': firstName,
          'last_name': lastName,
          'course': course,
          'year_level': yearLevel,
          'enrollment_status': 'Active',
          'role': 'Student',
          'agreed_to_terms': true,
        });

        // ── 2. wallet (references users.id) ──────────────────────────────
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

        // ── 3. loans (references users.id) ───────────────────────────────
        final loanRow = await supabase
            .from('loans')
            .insert({
              'user_id': userId,
              'amount': 0.0,
              'purpose': 'Placeholder',
              'status': 'Pending',
              'ai_evaluation': 'Pending',
              'applied_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        final loanId = loanRow['id'] as String;

        // ── 4. child tables (all depend on wallet/loans/users above) ─────
        await supabase.from('repayment_schedule').insert({
          'loan_id': loanId,
          'due_date': DateTime.now().toIso8601String().substring(0, 10),
          'amount': 0.0,
          'status': 'Pending',
        });

        // active_loans rows are only created by the admin when a loan is approved.
        // Do NOT insert a placeholder here — it would show as a fake active loan
        // across Home, Loan, and E-Wallet tabs.

        // ── Upload study load image to Supabase Storage ─────────────────
        String fileUrl = '';
        if (studyLoadImage != null) {
          try {
            final ext = studyLoadImage.path.split('.').last.toLowerCase();
            final fileName = 'study_load_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
            final bytes = await studyLoadImage.readAsBytes();
            await supabase.storage.from('documents').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
                upsert: true,
              ),
            );
            fileUrl = supabase.storage.from('documents').getPublicUrl(fileName);
          } catch (uploadErr) {
            debugPrint('Study load upload error: $uploadErr');
            // Non-fatal: registration continues, file_url stays empty
          }
        }

        await supabase.from('documents').insert({
          'user_id': userId,
          'loan_id': loanId,
          'file_url': fileUrl,
          'uploaded_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'Welcome',
          'message': 'Welcome to LoanMate!',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('transactions').insert({
          'wallet_id': walletId,
          'type': 'init',
          'amount': 0.0,
          'date': DateTime.now().toIso8601String(),
          'description': 'Account Created',
        });

        return {'success': true, 'message': 'Registration Successful!'};
      } else {
        return {'success': false, 'message': 'Sign Up Failed. Try again.'};
      }
    } on AuthException catch (e) {
      // Supabase returns 422 when the email address is already registered
      if (e.statusCode == '422' ||
          e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already been registered') ||
          e.message.toLowerCase().contains('user already registered')) {
        return {
          'success': false,
          'message':
              'This Student ID is already registered. Please log in instead.',
          'code': 'duplicate',
        };
      }
      if (e.message.contains('rate limit') || e.statusCode == '429') {
        return {
          'success': false,
          'message': 'Too many attempts. Please wait a minute and try again.',
        };
      }
      return {'success': false, 'message': 'Auth error: ${e.message}'};
    } on PostgrestException catch (e) {
      debugPrint('Registration DB insert failed:');
      debugPrint('  code   : ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  details: ${e.details}');

      // Postgres unique-constraint violation code
      if (e.code == '23505') {
        final detail = e.details?.toString().toLowerCase() ?? '';
        if (detail.contains('student_id')) {
          return {
            'success': false,
            'message':
                'Student ID is already registered. Please log in instead.',
            'code': 'duplicate',
          };
        }
        return {
          'success': false,
          'message':
              'An account with this information already exists.',
          'code': 'duplicate',
        };
      }
      return {
        'success': false,
        'message': 'DB error [${e.code}]: ${e.message}',
      };
    } catch (e) {
      debugPrint('Registration unexpected error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── SIGN IN (with lockout) ────────────────────────────────────────────────
  Future<Map<String, dynamic>> signIn({
    required String studentId,
    required String password,
  }) async {
    // 1. Check current lockout status
    final lockStatus = await _checkLockout(studentId);
    if (lockStatus['locked'] == true) {
      return {
        'success': false,
        'message': lockStatus['message'],
        'locked': true,
        'remaining_seconds': lockStatus['remaining_seconds'],
      };
    }

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: toEmail(studentId),
        password: password,
      );

      if (response.user != null) {
        // Success → clear any recorded attempts
        await _clearAttempts(studentId);

        // Fetch role from users table for routing
        String role = 'student';
        try {
          final userRow = await supabase
              .from('users')
              .select('role')
              .eq('id', response.user!.id)
              .maybeSingle();
          role = (userRow?['role']?.toString() ?? 'student').toLowerCase();
        } catch (_) {}

        return {'success': true, 'message': 'Login Successful!', 'role': role};
      } else {
        await _recordFailedAttempt(studentId);
        return {'success': false, 'message': 'Invalid Credentials.'};
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login') ||
          e.message.toLowerCase().contains('invalid credentials')) {
        final attemptInfo = await _recordFailedAttempt(studentId);
        final remaining = _kMaxAttempts - (attemptInfo['attempt_count'] as int);
        if (remaining <= 0) {
          return {
            'success': false,
            'message':
                'Too many failed attempts. Account locked for 5 minutes.',
            'locked': true,
            'remaining_seconds': _kLockoutDuration.inSeconds,
          };
        }
        return {
          'success': false,
          'message':
              'Wrong Student ID or Password. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
        };
      }
      return {'success': false, 'message': 'Login Error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // ── GET CURRENT USER ──────────────────────────────────────────────────────
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
      debugPrint('Error Fetching Current User: $e');
      return null;
    }
  }

  // ── PRIVATE: lockout helpers ───────────────────────────────────────────────

  /// Returns {'locked': bool, 'message': String, 'remaining_seconds': int}
  Future<Map<String, dynamic>> _checkLockout(String studentId) async {
    try {
      final rows = await supabase
          .from('login_attempts')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (rows == null) return {'locked': false};

      final lockedUntil = rows['locked_until'] == null
          ? null
          : DateTime.parse(rows['locked_until'] as String);

      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        final remaining = lockedUntil.difference(DateTime.now());
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        return {
          'locked': true,
          'message': minutes > 0
              ? 'Account locked. Try again in ${minutes}m ${seconds}s.'
              : 'Account locked. Try again in ${seconds}s.',
          'remaining_seconds': remaining.inSeconds,
        };
      }
      return {'locked': false};
    } catch (e) {
      debugPrint('Lockout check error: $e');
      return {'locked': false};
    }
  }

  /// Records a failed attempt; locks account if threshold is reached.
  /// Returns the updated row map.
  Future<Map<String, dynamic>> _recordFailedAttempt(String studentId) async {
    try {
      // Upsert: increment count and update timestamp
      final existing = await supabase
          .from('login_attempts')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      final int newCount =
          ((existing?['attempt_count'] as int?) ?? 0) + 1;
      final DateTime now = DateTime.now();
      final DateTime? lockUntil =
          newCount >= _kMaxAttempts ? now.add(_kLockoutDuration) : null;

      await supabase.from('login_attempts').upsert({
        'student_id': studentId,
        'attempt_count': newCount,
        'last_attempt_at': now.toIso8601String(),
        'locked_until': lockUntil?.toIso8601String(),
      }, onConflict: 'student_id');

      return {'attempt_count': newCount, 'locked_until': lockUntil};
    } catch (e) {
      debugPrint('Record failed attempt error: $e');
      return {'attempt_count': 1};
    }
  }

  /// Clears the attempt counter after a successful login.
  Future<void> _clearAttempts(String studentId) async {
    try {
      await supabase
          .from('login_attempts')
          .delete()
          .eq('student_id', studentId);
    } catch (e) {
      debugPrint('Clear attempts error: $e');
    }
  }
}
