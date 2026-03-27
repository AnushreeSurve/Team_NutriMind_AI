// lib/utils/helpers.dart

import 'package:intl/intl.dart';

class Helpers {
  static String todayDate() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('d MMM yyyy').format(d);
    } catch (_) {
      return date;
    }
  }

  static String slotEmoji(String slot) {
    switch (slot) {
      case 'breakfast': return '🌅';
      case 'lunch':     return '☀️';
      case 'snack':     return '🍎';
      case 'dinner':    return '🌙';
      default:          return '🍽️';
    }
  }

  static String metabolicEmoji(String state) {
    switch (state) {
      case 'performance':     return '🚀';
      case 'stress_recovery': return '🌿';
      case 'fat_burn':        return '🔥';
      case 'cortisol_buffer': return '🧘';
      case 'muscle_repair':   return '💪';
      default:                return '✨';
    }
  }

  static String formatMetabolicState(String state) =>
      state.replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
          .join(' ');

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}
