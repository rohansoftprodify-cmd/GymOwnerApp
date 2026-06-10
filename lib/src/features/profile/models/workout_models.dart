import 'package:gym_owner_app/src/features/profile/models/diet_goal_info.dart';

class WorkoutCategoryItem {
  WorkoutCategoryItem({
    required this.id,
    required this.goalKey,
    required this.name,
    this.description,
    this.coachingTips,
  });

  final String id;
  final String goalKey;
  final String name;
  final String? description;
  final String? coachingTips;

  DietGoalInfo? get goalInfo => DietGoalInfo.forKey(goalKey);

  factory WorkoutCategoryItem.fromMap(Map<String, dynamic> map) {
    return WorkoutCategoryItem(
      id: map['id'] as String,
      goalKey: map['goal_key'] as String? ?? 'healthy',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      coachingTips: map['coaching_tips'] as String?,
    );
  }
}

class WorkoutPlanSummary {
  WorkoutPlanSummary({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.goalKey,
    required this.categoryName,
    this.description,
    this.durationWeeks = 4,
    this.sessionsPerWeek = 3,
    this.experienceLevel = 'beginner',
    this.equipmentHint,
    this.isActive = true,
    this.sessionCount = 0,
    this.linkedMembershipPlanNames = const [],
  });

  final String? id;
  final String name;
  final String categoryId;
  final String goalKey;
  final String categoryName;
  final String? description;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String experienceLevel;
  final String? equipmentHint;
  final bool isActive;
  final int sessionCount;
  final List<String> linkedMembershipPlanNames;

  DietGoalInfo? get goalInfo => DietGoalInfo.forKey(goalKey);

  factory WorkoutPlanSummary.fromMap(Map<String, dynamic> map) {
    final cat = map['workout_plan_categories'] as Map<String, dynamic>? ?? const {};
    final rawLinks = map['subscription_plan_workout_plans'] as List<dynamic>? ?? [];
    final linkedNames = rawLinks
        .cast<Map<String, dynamic>>()
        .map((link) {
          final plan = link['subscription_plans'] as Map<String, dynamic>?;
          return plan?['name'] as String?;
        })
        .whereType<String>()
        .toList();
    return WorkoutPlanSummary(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? '',
      goalKey: cat['goal_key'] as String? ?? 'healthy',
      categoryName: cat['name'] as String? ?? '-',
      description: map['description'] as String?,
      durationWeeks: map['duration_weeks'] as int? ?? 4,
      sessionsPerWeek: map['sessions_per_week'] as int? ?? 3,
      experienceLevel: map['experience_level'] as String? ?? 'beginner',
      equipmentHint: map['equipment_hint'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      sessionCount: map['session_count'] as int? ?? 0,
      linkedMembershipPlanNames: linkedNames,
    );
  }
}

class WorkoutSessionExerciseItem {
  WorkoutSessionExerciseItem({
    this.id,
    required this.exerciseName,
    this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds,
    this.notes,
    this.sortOrder = 0,
  });

  final String? id;
  final String exerciseName;
  final String? exerciseId;
  final int sets;
  final int reps;
  final int? restSeconds;
  final String? notes;
  final int sortOrder;

  Map<String, dynamic> toRow(String gymId, String sessionId) => {
        if (id != null) 'id': id,
        'gym_id': gymId,
        'workout_session_id': sessionId,
        if (exerciseId != null) 'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'sets': sets,
        'reps': reps,
        'rest_seconds': restSeconds,
        'notes': notes,
        'sort_order': sortOrder,
      };

  factory WorkoutSessionExerciseItem.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionExerciseItem(
      id: map['id'] as String?,
      exerciseName: map['exercise_name'] as String? ?? '',
      exerciseId: map['exercise_id'] as String?,
      sets: map['sets'] as int? ?? 3,
      reps: map['reps'] as int? ?? 10,
      restSeconds: map['rest_seconds'] as int?,
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

class WorkoutSessionItem {
  WorkoutSessionItem({
    this.id,
    required this.dayLabel,
    this.dayNumber = 1,
    this.guidance,
    this.sortOrder = 0,
    this.exercises = const [],
  });

  final String? id;
  final String dayLabel;
  final int dayNumber;
  final String? guidance;
  final int sortOrder;
  final List<WorkoutSessionExerciseItem> exercises;

  factory WorkoutSessionItem.fromMap(Map<String, dynamic> map) {
    final rawExercises = map['workout_session_exercises'] as List<dynamic>? ??
        map['exercises'] as List<dynamic>? ??
        [];
    return WorkoutSessionItem(
      id: map['id'] as String?,
      dayLabel: map['day_label'] as String? ?? '',
      dayNumber: map['day_number'] as int? ?? 1,
      guidance: map['guidance'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      exercises: rawExercises
          .cast<Map<String, dynamic>>()
          .map(WorkoutSessionExerciseItem.fromMap)
          .toList(),
    );
  }
}
