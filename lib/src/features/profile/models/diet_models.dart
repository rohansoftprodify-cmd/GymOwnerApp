import 'package:gym_owner_app/src/features/profile/models/diet_goal_info.dart';

class DietCategoryItem {
  DietCategoryItem({
    required this.id,
    required this.goalKey,
    required this.name,
    this.description,
    this.nutritionTips,
  });

  final String id;
  final String goalKey;
  final String name;
  final String? description;
  final String? nutritionTips;

  DietGoalInfo? get goalInfo => DietGoalInfo.forKey(goalKey);

  factory DietCategoryItem.fromMap(Map<String, dynamic> map) {
    return DietCategoryItem(
      id: map['id'] as String,
      goalKey: map['goal_key'] as String? ?? 'healthy',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      nutritionTips: map['nutrition_tips'] as String?,
    );
  }
}

class DietPlanSummary {
  DietPlanSummary({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.goalKey,
    required this.categoryName,
    this.description,
    this.imageUrl,
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.hydrationLiters,
    this.durationDays = 7,
    this.isActive = true,
    this.mealCount = 0,
    this.linkedMembershipPlanNames = const [],
  });

  final String? id;
  final String name;
  final String categoryId;
  final String goalKey;
  final String categoryName;
  final String? description;
  final String? imageUrl;
  final int? targetCalories;
  final double? targetProteinG;
  final double? targetCarbsG;
  final double? targetFatG;
  final double? hydrationLiters;
  final int durationDays;
  final bool isActive;
  final int mealCount;
  final List<String> linkedMembershipPlanNames;

  bool get isMembershipRestricted => linkedMembershipPlanNames.isNotEmpty;

  DietGoalInfo? get goalInfo => DietGoalInfo.forKey(goalKey);

  factory DietPlanSummary.fromMap(
    Map<String, dynamic> map, {
    String? Function(String? path)? imageUrlResolver,
  }) {
    final cat = map['diet_plan_categories'] as Map<String, dynamic>? ?? const {};
    final rawLinks = map['subscription_plan_diet_plans'] as List<dynamic>? ?? [];
    final linkedNames = rawLinks
        .cast<Map<String, dynamic>>()
        .map((link) {
          final plan = link['subscription_plans'] as Map<String, dynamic>?;
          return plan?['name'] as String?;
        })
        .whereType<String>()
        .toList();
    return DietPlanSummary(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? '',
      goalKey: cat['goal_key'] as String? ?? 'healthy',
      categoryName: cat['name'] as String? ?? '-',
      description: map['description'] as String?,
      imageUrl: imageUrlResolver?.call(map['image_path'] as String?),
      targetCalories: map['target_calories'] as int?,
      targetProteinG: (map['target_protein_g'] as num?)?.toDouble(),
      targetCarbsG: (map['target_carbs_g'] as num?)?.toDouble(),
      targetFatG: (map['target_fat_g'] as num?)?.toDouble(),
      hydrationLiters: (map['hydration_liters'] as num?)?.toDouble(),
      durationDays: map['duration_days'] as int? ?? 7,
      isActive: map['is_active'] as bool? ?? true,
      mealCount: map['meal_count'] as int? ?? 0,
      linkedMembershipPlanNames: linkedNames,
    );
  }
}

class DietMealItem {
  DietMealItem({
    required this.id,
    required this.mealLabel,
    this.mealTime,
    this.guidance,
    this.sortOrder = 0,
    this.foods = const [],
  });

  final String? id;
  final String mealLabel;
  final String? mealTime;
  final String? guidance;
  final int sortOrder;
  final List<DietFoodItem> foods;

  int get totalCalories => foods.fold(0, (s, f) => s + (f.calories ?? 0));

  factory DietMealItem.fromMap(Map<String, dynamic> map) {
    final rawFoods = map['diet_food_items'] as List<dynamic>? ?? [];
    final foods = rawFoods
        .cast<Map<String, dynamic>>()
        .map(DietFoodItem.fromMap)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return DietMealItem(
      id: map['id'] as String?,
      mealLabel: map['meal_label'] as String? ?? '',
      mealTime: map['meal_time'] as String?,
      guidance: map['guidance'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      foods: foods,
    );
  }
}

class DietFoodItem {
  DietFoodItem({
    this.id,
    required this.foodName,
    this.portion,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.notes,
    this.sortOrder = 0,
  });

  final String? id;
  final String foodName;
  final String? portion;
  final int? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String? notes;
  final int sortOrder;

  factory DietFoodItem.fromMap(Map<String, dynamic> map) {
    return DietFoodItem(
      id: map['id'] as String?,
      foodName: map['food_name'] as String? ?? '',
      portion: map['portion'] as String?,
      calories: map['calories'] as int?,
      proteinG: (map['protein_g'] as num?)?.toDouble(),
      carbsG: (map['carbs_g'] as num?)?.toDouble(),
      fatG: (map['fat_g'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toRow(String gymId, String mealId) {
    return {
      if (id != null) 'id': id,
      'gym_id': gymId,
      'diet_meal_id': mealId,
      'food_name': foodName,
      'portion': portion,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'notes': notes,
      'sort_order': sortOrder,
    };
  }
}

class DietPlanDetail {
  DietPlanDetail({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.goalKey,
    required this.categoryName,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.hydrationLiters,
    this.durationDays = 7,
    this.isActive = true,
    this.meals = const [],
  });

  final String id;
  final String name;
  final String categoryId;
  final String goalKey;
  final String categoryName;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final int? targetCalories;
  final double? targetProteinG;
  final double? targetCarbsG;
  final double? targetFatG;
  final double? hydrationLiters;
  final int durationDays;
  final bool isActive;
  final List<DietMealItem> meals;

  DietGoalInfo? get goalInfo => DietGoalInfo.forKey(goalKey);
}
