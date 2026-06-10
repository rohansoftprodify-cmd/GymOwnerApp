import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline workout plan templates — no edge function or OpenAI required.
class WorkoutTemplateGenerator {
  WorkoutTemplateGenerator._();

  static List<Map<String, dynamic>>? _templates;

  static Future<void> _ensureLoaded() async {
    if (_templates != null) return;
    final raw = await rootBundle.loadString('assets/data/workout_templates.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _templates = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static String _normalizeEquipment(String? hint) => (hint ?? '').toLowerCase().trim();

  static Map<String, dynamic> _findTemplate(
    List<Map<String, dynamic>> templates, {
    required String goalKey,
    String experienceLevel = 'beginner',
    String? equipmentHint,
    int? sessionsPerWeek,
  }) {
    final equipment = _normalizeEquipment(equipmentHint);

    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final t in templates) {
      if (t['goal_key'] != goalKey) continue;
      var score = 0;
      if (t['experience_level'] == experienceLevel) score += 3;
      if (sessionsPerWeek != null && t['sessions_per_week'] == sessionsPerWeek) score += 2;
      final tEquip = _normalizeEquipment(t['equipment_hint'] as String?);
      if (equipment.isNotEmpty && tEquip.contains(equipment)) score += 4;
      if (equipment.contains('dumbbell') && tEquip.contains('dumbbell')) score += 5;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }

    if (best != null) return best;
    return templates.firstWhere(
      (t) => t['goal_key'] == goalKey,
      orElse: () => templates.first,
    );
  }

  static Future<Map<String, dynamic>> generate({
    required String goalKey,
    String experienceLevel = 'beginner',
    String? equipmentHint,
    int? sessionsPerWeek,
    int? durationWeeks,
    int? memberAge,
    double? memberWeightKg,
  }) async {
    await _ensureLoaded();
    final template = _findTemplate(
      _templates!,
      goalKey: goalKey,
      experienceLevel: experienceLevel,
      equipmentHint: equipmentHint,
      sessionsPerWeek: sessionsPerWeek,
    );

    final spw = sessionsPerWeek ?? template['sessions_per_week'] as int? ?? 3;
    final weeks = durationWeeks ?? template['duration_weeks'] as int? ?? 4;

    var description = template['description'] as String? ?? '';
    if (memberAge != null) description = '$description Tailored for age $memberAge.';
    if (memberWeightKg != null) {
      description = '$description Member weight: ${memberWeightKg}kg.';
    }

    final rawSessions = template['sessions'] as List<dynamic>;
    final sessions = rawSessions.asMap().entries.map((entry) {
      final session = Map<String, dynamic>.from(entry.value as Map);
      final rawExercises = session['exercises'] as List<dynamic>;
      return {
        'day_label': session['day_label'],
        'day_number': entry.key + 1,
        'guidance': session['guidance'],
        'exercises': rawExercises.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      };
    }).toList();

    var name = template['name'] as String? ?? 'Workout plan';
    name = name.replaceAll(RegExp(r'\d-Day'), '$spw-Day');

    return {
      'name': name,
      'description': description.trim(),
      'duration_weeks': weeks,
      'sessions_per_week': spw,
      'experience_level': experienceLevel,
      'equipment_hint': equipmentHint ?? template['equipment_hint'],
      'sessions': sessions,
    };
  }
}
