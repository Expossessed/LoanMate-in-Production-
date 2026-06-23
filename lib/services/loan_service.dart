import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoanService {
  //applying for loan
  Future<Map<String, dynamic>> applyForLoan({
    required String userId,
    required double amount,
    required String purpose,
  }) async {
    try {
      await supabase.from('loans').insert({
        'user_id': userId,
        'amount': amount,
        'purpose': purpose,
        'status': 'Pending',
        'ai_evaluation': 'Pending',
        'applied_at': DateTime.now().toIso8601String(),
      });
      return {'success': true, 'message': 'Loan application submitted!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  //getting loan history
  Future<List<Map<String, dynamic>>> getLoanHistory(String userId) async {
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

  // pending loans
  Future<List<Map<String, dynamic>>> getPendingLoans({String? userId}) async {
    try {
      var query = supabase.from('loans').select().eq('status', 'Pending');
      if (userId != null) query = query.eq('user_id', userId);
      final response = await query.order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending loans: $e');
      return [];
    }
  }

  // approve loan (to be done with AI)
  Future<Map<String, dynamic>> approveLoan(String loanId) async {
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

  // reject loan (to be done with AI)
  Future<Map<String, dynamic>> rejectLoan(String loanId) async {
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

  // AI evaluation if they are eligible or not
  Future<Map<String, String>> getAiEvaluation(String userId) async {
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
