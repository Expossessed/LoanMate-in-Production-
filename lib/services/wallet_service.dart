// ============================================================================
// 💳 WALLET SERVICE — Handles wallet balance, payments, and auto-deductions.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class WalletService {
  // ── GET BALANCE ──
  Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      final response = await supabase
          .from('wallet')
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching wallet: $e');
      return {'balance': 0.0, 'savings_goal': 0.0, 'current_savings': 0.0};
    }
  }

  // ── GET PAYMENT HISTORY ──
  Future<List<Map<String, String>>> getPaymentHistory(String userId) async {
    try {
      final wallet = await supabase
          .from('wallet')
          .select('id')
          .eq('user_id', userId)
          .single();

      final response = await supabase
          .from('transactions')
          .select()
          .eq('wallet_id', wallet['id'])
          .eq('type', 'payment')
          .order('date', ascending: false);

      // Convert each DB row into the format your widgets expect
      return List<Map<String, String>>.from(
        response.map((item) {
          return {
            'date': item['date']?.toString() ?? '',
            'amount': '₱${item['amount']}',
            'status': item['description'] ?? 'Paid',
          };
        }),
      );
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // ── GET AUTO-DEDUCTION LOG ──
  Future<List<Map<String, String>>> getAutoDeductionLog(String userId) async {
    try {
      final wallet = await supabase
          .from('wallet')
          .select('id')
          .eq('user_id', userId)
          .single();

      final response = await supabase
          .from('transactions')
          .select()
          .eq('wallet_id', wallet['id'])
          .eq('type', 'auto_deduction')
          .order('date', ascending: false);

      return List<Map<String, String>>.from(
        response.map((item) {
          return {
            'description': item['description']?.toString() ?? '',
            'date': item['date']?.toString() ?? '',
          };
        }),
      );
    } catch (e) {
      print('Error fetching auto-deduction log: $e');
      return [];
    }
  }

  // ── TOP UP ──
  Future<Map<String, dynamic>> topUp({
    required String userId,
    required double amount,
  }) async {
    try {
      final wallet = await supabase
          .from('wallet')
          .select()
          .eq('user_id', userId)
          .single();

      final newBalance = (wallet['balance'] as num) + amount;

      await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', userId);

      await supabase.from('transactions').insert({
        'wallet_id': wallet['id'],
        'type': 'top_up',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet top-up',
      });

      return {'success': true, 'new_balance': newBalance};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ── WITHDRAW ──
  Future<Map<String, dynamic>> withdraw({
    required String userId,
    required double amount,
  }) async {
    try {
      final wallet = await supabase
          .from('wallet')
          .select()
          .eq('user_id', userId)
          .single();

      final currentBalance = (wallet['balance'] as num).toDouble();
      if (currentBalance < amount) {
        return {'success': false, 'message': 'Insufficient balance.'};
      }

      final newBalance = currentBalance - amount;
      await supabase
          .from('wallet')
          .update({'balance': newBalance})
          .eq('user_id', userId);

      await supabase.from('transactions').insert({
        'wallet_id': wallet['id'],
        'type': 'withdrawal',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'description': 'Wallet withdrawal',
      });

      return {'success': true, 'new_balance': newBalance};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
