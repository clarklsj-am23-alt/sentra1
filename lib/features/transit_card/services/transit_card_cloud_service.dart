import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transit_card_model.dart';

class TransitCardCloudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CLOUD DB: Upload / Sync Card to Supabase
  Future<void> syncCardToCloud(TransitCard card) async {
    try {
      await _supabase.from('user_transit_cards').upsert(
        {
          'local_id': card.id,
          'card_name': card.cardName,
          'card_number': card.cardNumber,
          'balance': card.balance,
          'card_type': card.cardType,
          'last_synced': DateTime.now().toIso8601String(),
        },
        onConflict: 'local_id',
      );
    } catch (e) {
      // Offline fallback: if network fails, local SQLite remains source of truth
    }
  }

  // CLOUD DB: Read Cards from Supabase
  Future<List<Map<String, dynamic>>> fetchCloudCards() async {
    final response = await _supabase
        .from('user_transit_cards')
        .select()
        .order('last_synced', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // CLOUD DB: Delete Card from Supabase
  Future<void> deleteCardFromCloud(int localId) async {
    try {
      await _supabase
          .from('user_transit_cards')
          .delete()
          .eq('local_id', localId);
    } catch (_) {}
  }
}