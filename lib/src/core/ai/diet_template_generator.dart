import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline diet plan templates — no edge function or OpenAI required.
class DietTemplateGenerator {
  DietTemplateGenerator._();

  static List<Map<String, dynamic>>? _templates;

  static Future<void> _ensureLoaded() async {
    if (_templates != null) return;
    final raw = await rootBundle.loadString('assets/data/diet_templates.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _templates = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static double _round1(double value) => (value * 10).roundToDouble() / 10;

  static int _estimateCalories(String goalKey, double? weightKg) {
    if (weightKg != null && weightKg > 0) {
      switch (goalKey) {
        case 'weight_loss':
          return (weightKg * 24 - 400).round().clamp(1400, 10000);
        case 'muscle_gain':
          return (weightKg * 30 + 300).round();
        default:
          return (weightKg * 26).round();
      }
    }
    switch (goalKey) {
      case 'weight_loss':
        return 1800;
      case 'muscle_gain':
        return 2800;
      default:
        return 2200;
    }
  }

  static int _estimateProtein(String goalKey, double? weightKg, double scaled) {
    if (weightKg != null && weightKg > 0) {
      final factor = goalKey == 'healthy' ? 1.4 : 2.0;
      return (weightKg * factor).round();
    }
    return scaled.round();
  }

  static Map<String, dynamic> _findTemplate(
    List<Map<String, dynamic>> templates,
    String goalKey,
    String dietaryPreference,
  ) {
    for (final t in templates) {
      if (t['goal_key'] == goalKey && t['dietary_preference'] == dietaryPreference) {
        return t;
      }
    }
    for (final t in templates) {
      if (t['goal_key'] == goalKey) return t;
    }
    return templates.first;
  }

  static Future<Map<String, dynamic>> generate({
    required String goalKey,
    String dietaryPreference = 'veg',
    int? targetCalories,
    double? memberWeightKg,
    String? cuisineHint,
  }) async {
    await _ensureLoaded();
    final templates = _templates!;
    final template = _findTemplate(templates, goalKey, dietaryPreference);
    final calories = targetCalories ?? _estimateCalories(goalKey, memberWeightKg);
    final baseCalories = (template['base_calories'] as num).toDouble();
    final factor = calories / baseCalories;

    final rawMeals = template['meals'] as List<dynamic>;
    final meals = <Map<String, dynamic>>[];
    for (final rawMeal in rawMeals) {
      final meal = Map<String, dynamic>.from(rawMeal as Map);
      final foods = <Map<String, dynamic>>[];
      for (final rawFood in meal['foods'] as List<dynamic>) {
        final food = Map<String, dynamic>.from(rawFood as Map);
        foods.add({
          'food_name': food['food_name'],
          'portion': food['portion'],
          'calories': ((food['calories'] as num) * factor).round().clamp(1, 100000),
          'protein_g': _round1((food['protein_g'] as num).toDouble() * factor),
          'carbs_g': _round1((food['carbs_g'] as num).toDouble() * factor),
          'fat_g': _round1((food['fat_g'] as num).toDouble() * factor),
          if (food['notes'] != null) 'notes': food['notes'],
        });
      }
      meals.add({
        'meal_label': meal['meal_label'],
        'meal_time': meal['meal_time'],
        'guidance': meal['guidance'],
        'foods': foods,
      });
    }

    final durationDays = template['duration_days'] as int? ?? 7;
    final cuisineNote = cuisineHint?.trim();
    var description = template['description'] as String? ?? '';
    if (cuisineNote != null && cuisineNote.isNotEmpty) {
      description = '$description Styled for: $cuisineNote.';
    }

    final name = (template['name'] as String? ?? 'Diet plan')
        .replaceAll('7-Day', '$durationDays-Day');

    return {
      'name': name,
      'description': description,
      'target_calories': calories,
      'target_protein_g': _estimateProtein(
        goalKey,
        memberWeightKg,
        (template['target_protein_g'] as num).toDouble() * factor,
      ),
      'target_carbs_g': _round1((template['target_carbs_g'] as num).toDouble() * factor),
      'target_fat_g': _round1((template['target_fat_g'] as num).toDouble() * factor),
      'hydration_liters': (template['hydration_liters'] as num).toDouble(),
      'duration_days': durationDays,
      'meals': meals,
    };
  }
}
