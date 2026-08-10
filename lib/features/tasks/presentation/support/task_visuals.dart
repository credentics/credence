import 'package:flutter/material.dart';

/// Catalogue of accent colours + icons offered when creating a task list.
/// Kept small on purpose — picking one of each shouldn't feel like a form.
class TaskVisualOptions {
  const TaskVisualOptions._();

  static const List<String> accentColors = <String>[
    '#2A1464',
    '#2563EB',
    '#059669',
    '#D97706',
    '#DC2626',
    '#8B5CF6',
    '#0EA5E9',
    '#EC4899',
  ];

  static const List<String> iconKeys = <String>[
    'checklist',
    'flag',
    'star',
    'home',
    'work',
    'flight',
    'shopping',
    'medical',
  ];

  static IconData iconFor(String key) {
    switch (key) {
      case 'flag':
        return Icons.flag_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'checklist':
      default:
        return Icons.checklist_rounded;
    }
  }

  static Color parseAccent(String hex, {Color fallback = const Color(0xFF2A1464)}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    if (cleaned.length == 6) {
      return Color(0xFF000000 | value);
    }
    return Color(value);
  }
}
