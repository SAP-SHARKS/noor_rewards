// lib/services/donation_service.dart
// Handles donations to community projects via Supabase

import 'package:supabase_flutter/supabase_flutter.dart';

class DonationService {
  DonationService._();
  static final DonationService instance = DonationService._();

  final _sb = Supabase.instance.client;

  /// Donates [amount] to a community [projectId].
  /// Returns null if successful, otherwise an error string.
  Future<String?> donate(String projectId, int amount) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return "You must be logged in to donate.";
    
    try {
      final success = await _sb.rpc('donate_to_project', params: {
        'p_user_id': uid,
        'p_project_id': projectId,
        'p_amount': amount,
      });
      
      if (success == true) {
        return null; // Null means success
      } else {
        return "Donation could not be processed at this time.";
      }
    } catch (e) {
      if (e is PostgrestException) {
        return e.message; // Propagate the specific SQL exception (like "Insufficient noor points balance")
      }
      return "An unexpected network error occurred.";
    }
  }

  /// Calculates the total lifetime donations made by the current user.
  Future<int> getUserTotalDonations() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0;
    
    try {
      final response = await _sb
          .from('user_donations')
          .select('points_donated')
          .eq('user_id', uid);
          
      int total = 0;
      for (final row in response) {
        total += (row['points_donated'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Returns a list of projects the current user has donated to,
  /// with their personal donation total and project details.
  Future<List<Map<String, dynamic>>> getUserProjectDonations() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final List<dynamic> data = await _sb.rpc(
        'get_user_project_donations',
        params: {'p_user_id': uid},
      );
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
