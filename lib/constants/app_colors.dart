import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentBlue = Color(0xFF1565C0);
  static const Color backgroundCream = Color(0xFFF3EBE1);
  static const Color cardCream = Color(0xFFFAF7F2);

  static Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return primaryGreen;
      case 'paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.grey.shade900;
    }
  }

  static IconData statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'paid':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'overdue':
        return Icons.error_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color paymentColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    if (days <= 10) return Colors.yellow;
    if (days >= 15) return Colors.green;
    return Colors.amber.shade700;
  }

  static IconData paymentIcon(int days) {
    if (days < 0) return Icons.check_circle;
    if (days == 0) return Icons.error_outline_rounded;
    if (days <= 3) return Icons.error_outline_rounded;
    if (days <= 7)
      return Icons.access_time_rounded;
    else
      return Icons.info_outline_rounded;
  }

  static Color aiEvaluationColor(String e) {
    switch (e.toLowerCase()) {
      case 'good standing':
        return accentBlue;
      case 'at risk':
        return Colors.orange.shade800;
      case 'poor standing':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  static Color aiResultColor(String result) {
    switch (result.toLowerCase()) {
      case 'eligible':
        return primaryGreen;
      case 'not eligible':
        return Colors.red.shade700;
      case 'under review':
        return Colors.orange.shade800;
      default:
        return Colors.grey;
    }
  }

  static String aiResultIcon(String result) {
    switch (result.toLowerCase()) {
      case 'eligible':
        return '✓';
      case 'not eligible':
        return '✗';
      case 'under review':
        return '⏳';
      default:
        return '•';
    }
  }

  static Color loanHistoryColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return primaryGreen;
      case 'approved':
        return Colors.amber.shade700;
      case 'partial':
        return Colors.orange.shade800;
      case 'overdue':
        return Colors.red.shade700;
      case 'denied':
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  static IconData loanHistoryIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'approved':
        return Icons.thumb_up_rounded;
      case 'partial':
        return Icons.timelapse_rounded;
      case 'overdue':
        return Icons.error_outline_rounded;
      case 'denied':
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color pendingLoanColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return primaryGreen;
      case 'denied':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  static IconData pendingLoanIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'denied':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color savingsColor(double progress) {
    if (progress < 0.30) return Colors.red;
    if (progress < 0.60) return Colors.orange;
    return primaryGreen;
  }

  static Color statusChipColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return primaryGreen;
      case 'overdue':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  static IconData statusLeadingIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'overdue':
        return Icons.error_outline_rounded;
      case 'active':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static IconData activityIcon(String key) {
    switch (key) {
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'send':
        return Icons.send_rounded;
      case 'cancel':
        return Icons.cancel_rounded;
      case 'warning':
        return Icons.warning_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color walletPaymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return primaryGreen;
      case 'failed':
        return Colors.red.shade700;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData walletPaymentIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
