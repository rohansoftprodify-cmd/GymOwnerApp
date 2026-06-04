class ExerciseCategoryItem {
  ExerciseCategoryItem({required this.id, required this.name});

  final String id;
  final String name;

  factory ExerciseCategoryItem.fromMap(Map<String, dynamic> map) {
    return ExerciseCategoryItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
    );
  }
}

class ExerciseItem {
  ExerciseItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.imagePath,
    this.imageUrl,
    this.benefits,
    this.precautions,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String? imagePath;
  final String? imageUrl;
  final String? benefits;
  final String? precautions;
  final int defaultSets;
  final int defaultReps;
  final bool isActive;

  String get setsRepsLabel => '$defaultSets sets × $defaultReps reps';

  factory ExerciseItem.fromMap(
    Map<String, dynamic> map, {
    String? Function(String? path)? imageUrlResolver,
  }) {
    final category =
        map['exercise_categories'] as Map<String, dynamic>? ?? const {};
    final imagePath = map['image_path'] as String?;
    return ExerciseItem(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? '',
      categoryName: category['name'] as String? ?? '-',
      imagePath: imagePath,
      imageUrl: imageUrlResolver?.call(imagePath),
      benefits: map['benefits'] as String?,
      precautions: map['precautions'] as String?,
      defaultSets: map['default_sets'] as int? ?? 3,
      defaultReps: map['default_reps'] as int? ?? 10,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
