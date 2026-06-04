/// Evidence-based guidance for gym diet plan goals (trainer-facing copy).
class DietGoalInfo {
  const DietGoalInfo({
    required this.key,
    required this.title,
    required this.shortLabel,
    required this.summary,
    required this.calorieStrategy,
    required this.proteinGuide,
    required this.carbsGuide,
    required this.fatsGuide,
    required this.sampleFoods,
    required this.avoidFoods,
    required this.iconName,
  });

  final String key;
  final String title;
  final String shortLabel;
  final String summary;
  final String calorieStrategy;
  final String proteinGuide;
  final String carbsGuide;
  final String fatsGuide;
  final String sampleFoods;
  final String avoidFoods;
  final String iconName;

  static const weightLoss = DietGoalInfo(
    key: 'weight_loss',
    title: 'Weight Loss',
    shortLabel: 'Lose',
    summary:
        'Supports fat loss while preserving lean muscle. Best for members with a moderate calorie deficit and consistent training.',
    calorieStrategy:
        'Aim for ~300–500 kcal below estimated maintenance. Adjust every 2–3 weeks based on weight trend (target ~0.25–0.75 kg/week).',
    proteinGuide:
        'High protein: ~1.6–2.2 g per kg body weight daily to protect muscle during a cut.',
    carbsGuide:
        'Moderate carbs; prioritize around workouts. Emphasize vegetables, whole grains, and fiber.',
    fatsGuide:
        'Moderate healthy fats (nuts, olive oil, avocado). Avoid removing fats entirely.',
    sampleFoods:
        'Lean chicken, fish, eggs, dal, Greek yogurt, oats, salads, green vegetables, berries.',
    avoidFoods:
        'Sugary drinks, deep-fried foods, excess sweets, heavy late-night carb-only meals.',
    iconName: 'trending_down',
  );

  static const muscleGain = DietGoalInfo(
    key: 'muscle_gain',
    title: 'Muscle Gain',
    shortLabel: 'Gain',
    summary:
        'Supports lean mass and strength gains with a controlled calorie surplus and adequate protein.',
    calorieStrategy:
        'Aim for ~250–500 kcal above maintenance. Increase slowly if weight does not rise (~0.25–0.5 kg/week).',
    proteinGuide:
        'High protein: ~1.8–2.4 g per kg body weight daily, spread across 4–5 meals when possible.',
    carbsGuide:
        'Higher carbs around training for performance and recovery. Include rice, roti, potatoes, bananas.',
    fatsGuide:
        'Moderate fats for hormones and calories; add nuts, peanut butter, ghee in measured amounts.',
    sampleFoods:
        'Chicken, paneer, eggs, milk, rice, whole wheat roti, bananas, peanut butter, whey (if used).',
    avoidFoods:
        'Only junk calories (empty sugary foods). Surplus should come from quality whole foods.',
    iconName: 'fitness_center',
  );

  static const healthy = DietGoalInfo(
    key: 'healthy',
    title: 'Healthy Lifestyle',
    shortLabel: 'Healthy',
    summary:
        'Balanced maintenance nutrition for energy, recovery, and long-term health—not aggressive cut or bulk.',
    calorieStrategy:
        'Eat near maintenance calories. Focus on consistency, meal timing, and whole foods over strict dieting.',
    proteinGuide:
        'Adequate protein: ~1.2–1.6 g per kg body weight daily for active adults.',
    carbsGuide:
        'Balanced carbs from whole grains, fruits, and vegetables. Match activity level.',
    fatsGuide:
        'Include healthy fats daily; limit trans fats and heavily processed oils.',
    sampleFoods:
        'Mixed vegetables, fruits, whole grains, legumes, lean proteins, curd, nuts in moderation.',
    avoidFoods:
        'Excess packaged snacks, sugary beverages, skipping meals, very low protein intake.',
    iconName: 'favorite',
  );

  static const all = [weightLoss, muscleGain, healthy];

  static DietGoalInfo? forKey(String? key) {
    if (key == null) return null;
    for (final g in all) {
      if (g.key == key) return g;
    }
    return null;
  }
}
