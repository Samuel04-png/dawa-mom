import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared, server-derived unread count for the app-header bell.
///
/// Locally synthesized reminders are intentionally excluded: the badge must
/// never claim that a durable notification exists when it does not.
abstract final class DawaNotificationCounter {
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> pulse = ValueNotifier<int>(0);

  static Future<void> refresh({SupabaseClient? client}) async {
    final resolved = client ?? _tryClient();
    final userId = resolved?.auth.currentUser?.id;
    if (resolved == null || userId == null || userId.isEmpty) {
      unreadCount.value = 0;
      return;
    }
    try {
      final rows = await resolved
          .from('notifications')
          .select('id')
          .eq('profile_id', userId)
          .isFilter('archived_at', null)
          .isFilter('read_at', null)
          .limit(100);
      unreadCount.value = (rows as List).length;
    } on PostgrestException catch (error) {
      debugPrint('Notification unread count unavailable: ${error.code}');
      // Retain the last confirmed count on temporary network failures.
    }
  }

  static void announceIncoming() => pulse.value++;

  static SupabaseClient? _tryClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
