// ============================================================================
// 💰 LOAN SERVICE — Handles everything related to loans.
// HOW TO SWITCH: Uncomment "🔜 SUPABASE VERSION", delete "🟢 DUMMY VERSION"
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoanService {
  // ── APPLY FOR LOAN ──
  Future<Map<String, dynamic>> applyForLoan({
    required String userId,
    required double amount,
    required String purpose,
  }) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      await supabase.from('loans').insert({
        'user_id': userId,
        'amount': amount,
        'purpose': purpose,
        'status': 'pending',
        'ai_evaluation': 'pending',
        'applied_at': DateTime.now().toIso8601String(),
      });
      return {'success': true, 'message': 'Loan application submitted!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── GET LOAN HISTORY ──
  Future<List<Map<String, dynamic>>> getLoanHistory(String userId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      final response = await supabase
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching loan history: $e');
      return [];
    }
  }

  // ── GET PENDING LOANS ──
  Future<List<Map<String, dynamic>>> getPendingLoans({String? userId}) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      var query = supabase.from('loans').select().eq('status', 'pending');
      if (userId != null) query = query.eq('user_id', userId);
      final response = await query.order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending loans: $e');
      return [];
    }
  }

  // ── APPROVE LOAN (Admin) ──
  Future<Map<String, dynamic>> approveLoan(String loanId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      await supabase
          .from('loans')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId);
      return {'success': true, 'message': 'Loan approved!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── REJECT LOAN (Admin) ──
  Future<Map<String, dynamic>> rejectLoan(String loanId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      await supabase
          .from('loans')
          .update({'status': 'rejected'})
          .eq('id', loanId);
      return {'success': true, 'message': 'Loan rejected.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── GET AI EVALUATION ──
  Future<Map<String, String>> getAiEvaluation(String userId) async {
    // 🔜 SUPABASE VERSION (uncomment when Supabase project is ready):
    try {
      final response = await supabase
          .from('loans')
          .select('ai_evaluation')
          .eq('user_id', userId)
          .order('applied_at', ascending: false)
          .limit(1)
          .single();
      return {
        'result': response['ai_evaluation'] ?? 'Unknown',
        'risk_level': 'Unknown',
      };
    } catch (e) {
      return {'result': 'Unknown', 'risk_level': 'Unknown'};
    }
  }
}
