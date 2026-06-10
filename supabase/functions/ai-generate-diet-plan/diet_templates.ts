export type MealFood = {
  food_name: string;
  portion: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  notes?: string;
};

export type Meal = {
  meal_label: string;
  meal_time: string;
  guidance: string;
  foods: MealFood[];
};

export type DietTemplate = {
  key: string;
  goal_key: 'weight_loss' | 'muscle_gain' | 'healthy';
  dietary_preference: 'veg' | 'non_veg' | 'eggetarian';
  base_calories: number;
  name: string;
  description: string;
  target_protein_g: number;
  target_carbs_g: number;
  target_fat_g: number;
  hydration_liters: number;
  duration_days: number;
  meals: Meal[];
};

export type DietPlanResult = {
  name: string;
  description: string;
  target_calories: number;
  target_protein_g: number;
  target_carbs_g: number;
  target_fat_g: number;
  hydration_liters: number;
  duration_days: number;
  meals: Meal[];
};

const templates: DietTemplate[] = [
  {
    key: 'weight_loss_veg',
    goal_key: 'weight_loss',
    dietary_preference: 'veg',
    base_calories: 1800,
    name: '7-Day Lean Cut (Veg)',
    description: 'Moderate deficit plan with high protein and Indian vegetarian staples.',
    target_protein_g: 130,
    target_carbs_g: 170,
    target_fat_g: 55,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'High protein start; avoid sugary tea/coffee add-ons.',
        foods: [
          { food_name: 'Vegetable oats upma', portion: '1 bowl', calories: 280, protein_g: 10, carbs_g: 42, fat_g: 8 },
          { food_name: 'Low-fat milk', portion: '1 glass', calories: 90, protein_g: 6, carbs_g: 10, fat_g: 2 },
          { food_name: 'Soaked almonds', portion: '5 pieces', calories: 70, protein_g: 3, carbs_g: 2, fat_g: 6 },
        ],
      },
      {
        meal_label: 'Mid-morning',
        meal_time: '11:00',
        guidance: 'Light protein snack to control lunch hunger.',
        foods: [
          { food_name: 'Greek yogurt / hung curd', portion: '1 cup', calories: 120, protein_g: 12, carbs_g: 8, fat_g: 3 },
          { food_name: 'Apple', portion: '1 medium', calories: 80, protein_g: 0, carbs_g: 21, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Dal + roti + salad; control rice if added.',
        foods: [
          { food_name: 'Moong dal', portion: '1 katori', calories: 150, protein_g: 10, carbs_g: 22, fat_g: 3 },
          { food_name: 'Whole wheat roti', portion: '2 small', calories: 200, protein_g: 6, carbs_g: 38, fat_g: 4 },
          { food_name: 'Mixed vegetable sabzi', portion: '1 bowl', calories: 120, protein_g: 4, carbs_g: 14, fat_g: 5 },
          { food_name: 'Cucumber tomato salad', portion: '1 plate', calories: 40, protein_g: 2, carbs_g: 8, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Pre-workout',
        meal_time: '17:00',
        guidance: 'Light carbs 60–90 min before training.',
        foods: [
          { food_name: 'Banana', portion: '1 medium', calories: 105, protein_g: 1, carbs_g: 27, fat_g: 0 },
          { food_name: 'Black coffee (optional)', portion: '1 cup', calories: 5, protein_g: 0, carbs_g: 1, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Protein-focused; keep carbs moderate at night.',
        foods: [
          { food_name: 'Paneer bhurji', portion: '120 g paneer', calories: 280, protein_g: 22, carbs_g: 8, fat_g: 18 },
          { food_name: 'Sauteed vegetables', portion: '1 bowl', calories: 90, protein_g: 3, carbs_g: 12, fat_g: 3 },
          { food_name: 'Buttermilk', portion: '1 glass', calories: 50, protein_g: 3, carbs_g: 6, fat_g: 1 },
        ],
      },
    ],
  },
  {
    key: 'weight_loss_eggetarian',
    goal_key: 'weight_loss',
    dietary_preference: 'eggetarian',
    base_calories: 1800,
    name: '7-Day Lean Cut (Eggetarian)',
    description: 'Deficit plan with eggs and vegetarian meals for easy adherence.',
    target_protein_g: 135,
    target_carbs_g: 165,
    target_fat_g: 58,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'Protein-rich breakfast improves satiety through the morning.',
        foods: [
          { food_name: 'Boiled eggs', portion: '2 whole', calories: 140, protein_g: 12, carbs_g: 1, fat_g: 10 },
          { food_name: 'Multigrain toast', portion: '2 slices', calories: 160, protein_g: 6, carbs_g: 28, fat_g: 3 },
          { food_name: 'Green tea', portion: '1 cup', calories: 2, protein_g: 0, carbs_g: 0, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Mid-morning',
        meal_time: '11:00',
        guidance: 'Keep portions small; prioritize protein.',
        foods: [
          { food_name: 'Sprouts chaat', portion: '1 bowl', calories: 150, protein_g: 10, carbs_g: 20, fat_g: 3 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Balanced plate: protein + fiber + controlled starch.',
        foods: [
          { food_name: 'Rajma / chole', portion: '1 katori', calories: 180, protein_g: 9, carbs_g: 28, fat_g: 4 },
          { food_name: 'Brown rice', portion: '1/2 katori', calories: 110, protein_g: 2, carbs_g: 24, fat_g: 1 },
          { food_name: 'Salad', portion: '1 plate', calories: 50, protein_g: 2, carbs_g: 10, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Snack',
        meal_time: '17:30',
        guidance: 'Pre- or post-workout fuel depending on training time.',
        foods: [
          { food_name: 'Egg white omelette', portion: '3 whites + veg', calories: 90, protein_g: 12, carbs_g: 4, fat_g: 2 },
          { food_name: 'Orange', portion: '1 medium', calories: 60, protein_g: 1, carbs_g: 15, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Finish dinner 2–3 hours before sleep when possible.',
        foods: [
          { food_name: 'Palak paneer', portion: '1 bowl', calories: 260, protein_g: 16, carbs_g: 12, fat_g: 16 },
          { food_name: 'Roti', portion: '1 small', calories: 100, protein_g: 3, carbs_g: 19, fat_g: 2 },
          { food_name: 'Curd', portion: '1/2 cup', calories: 70, protein_g: 5, carbs_g: 6, fat_g: 2 },
        ],
      },
    ],
  },
  {
    key: 'weight_loss_non_veg',
    goal_key: 'weight_loss',
    dietary_preference: 'non_veg',
    base_calories: 1800,
    name: '7-Day Lean Cut (Non-veg)',
    description: 'High-protein deficit plan with lean chicken and fish options.',
    target_protein_g: 145,
    target_carbs_g: 155,
    target_fat_g: 55,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'Lean protein + complex carbs.',
        foods: [
          { food_name: 'Egg bhurji', portion: '2 eggs', calories: 180, protein_g: 14, carbs_g: 4, fat_g: 12 },
          { food_name: 'Oats', portion: '1/2 cup dry', calories: 150, protein_g: 5, carbs_g: 27, fat_g: 3 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Grilled protein with vegetables; limit oil.',
        foods: [
          { food_name: 'Grilled chicken breast', portion: '150 g', calories: 250, protein_g: 46, carbs_g: 0, fat_g: 6 },
          { food_name: 'Steamed rice', portion: '1/2 katori', calories: 110, protein_g: 2, carbs_g: 24, fat_g: 0 },
          { food_name: 'Green salad', portion: '1 plate', calories: 40, protein_g: 2, carbs_g: 8, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Snack',
        meal_time: '17:00',
        guidance: 'Light snack before evening training.',
        foods: [
          { food_name: 'Roasted chana', portion: '1 handful', calories: 120, protein_g: 6, carbs_g: 18, fat_g: 3 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Fish or chicken with vegetables.',
        foods: [
          { food_name: 'Fish curry (lean)', portion: '150 g fish', calories: 220, protein_g: 32, carbs_g: 8, fat_g: 8 },
          { food_name: 'Sauteed beans', portion: '1 bowl', calories: 90, protein_g: 4, carbs_g: 12, fat_g: 3 },
        ],
      },
    ],
  },
  {
    key: 'muscle_gain_veg',
    goal_key: 'muscle_gain',
    dietary_preference: 'veg',
    base_calories: 2800,
    name: '14-Day Muscle Builder (Veg)',
    description: 'Calorie surplus with paneer, dal, and carb timing around workouts.',
    target_protein_g: 170,
    target_carbs_g: 340,
    target_fat_g: 75,
    hydration_liters: 3.5,
    duration_days: 14,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '07:30',
        guidance: 'Calorie-dense start with protein and complex carbs.',
        foods: [
          { food_name: 'Paneer paratha', portion: '2 medium', calories: 520, protein_g: 20, carbs_g: 58, fat_g: 22 },
          { food_name: 'Curd', portion: '1 cup', calories: 140, protein_g: 10, carbs_g: 12, fat_g: 4 },
          { food_name: 'Banana shake (milk)', portion: '1 glass', calories: 220, protein_g: 8, carbs_g: 32, fat_g: 6 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:00',
        guidance: 'Dal + rice + paneer for recovery fuel.',
        foods: [
          { food_name: 'Rajma chawal', portion: '1 plate', calories: 480, protein_g: 18, carbs_g: 72, fat_g: 10 },
          { food_name: 'Paneer tikka', portion: '120 g', calories: 280, protein_g: 22, carbs_g: 6, fat_g: 18 },
          { food_name: 'Salad', portion: '1 bowl', calories: 60, protein_g: 2, carbs_g: 12, fat_g: 1 },
        ],
      },
      {
        meal_label: 'Pre-workout',
        meal_time: '16:30',
        guidance: 'Carbs 60–90 min before lifting.',
        foods: [
          { food_name: 'Peanut butter toast', portion: '2 slices', calories: 320, protein_g: 12, carbs_g: 36, fat_g: 14 },
          { food_name: 'Dates', portion: '3 pieces', calories: 90, protein_g: 1, carbs_g: 24, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Post-workout',
        meal_time: '19:00',
        guidance: 'Protein + carbs within 2 hours of training.',
        foods: [
          { food_name: 'Soya chunk curry', portion: '1 bowl', calories: 260, protein_g: 28, carbs_g: 18, fat_g: 8 },
          { food_name: 'White rice', portion: '1 katori', calories: 220, protein_g: 4, carbs_g: 48, fat_g: 1 },
        ],
      },
      {
        meal_label: 'Bedtime snack',
        meal_time: '22:00',
        guidance: 'Slow protein before sleep.',
        foods: [
          { food_name: 'Milk + almonds', portion: '1 glass + 8 nuts', calories: 250, protein_g: 12, carbs_g: 18, fat_g: 14 },
        ],
      },
    ],
  },
  {
    key: 'muscle_gain_eggetarian',
    goal_key: 'muscle_gain',
    dietary_preference: 'eggetarian',
    base_calories: 2800,
    name: '14-Day Muscle Builder (Eggetarian)',
    description: 'Surplus plan using eggs, dairy, and Indian staples.',
    target_protein_g: 175,
    target_carbs_g: 330,
    target_fat_g: 78,
    hydration_liters: 3.5,
    duration_days: 14,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '07:30',
        guidance: '4–5 eggs across breakfast improves daily protein.',
        foods: [
          { food_name: 'Masala omelette', portion: '3 eggs', calories: 280, protein_g: 21, carbs_g: 4, fat_g: 20 },
          { food_name: 'Poha', portion: '1 plate', calories: 300, protein_g: 6, carbs_g: 52, fat_g: 8 },
          { food_name: 'Milk', portion: '1 glass', calories: 150, protein_g: 8, carbs_g: 14, fat_g: 6 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:00',
        guidance: 'Complete meal with dal, rice, and vegetables.',
        foods: [
          { food_name: 'Chole chawal', portion: '1 plate', calories: 500, protein_g: 16, carbs_g: 78, fat_g: 12 },
          { food_name: 'Boiled eggs', portion: '2', calories: 140, protein_g: 12, carbs_g: 1, fat_g: 10 },
        ],
      },
      {
        meal_label: 'Snack',
        meal_time: '16:30',
        guidance: 'Pre-workout energy.',
        foods: [
          { food_name: 'Peanut butter banana sandwich', portion: '1', calories: 380, protein_g: 12, carbs_g: 48, fat_g: 16 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Paneer + roti for evening protein.',
        foods: [
          { food_name: 'Shahi paneer', portion: '1 bowl', calories: 420, protein_g: 22, carbs_g: 14, fat_g: 30 },
          { food_name: 'Roti', portion: '3', calories: 300, protein_g: 9, carbs_g: 57, fat_g: 6 },
        ],
      },
    ],
  },
  {
    key: 'muscle_gain_non_veg',
    goal_key: 'muscle_gain',
    dietary_preference: 'non_veg',
    base_calories: 2800,
    name: '14-Day Muscle Builder (Non-veg)',
    description: 'High-protein surplus with chicken, eggs, and rice.',
    target_protein_g: 185,
    target_carbs_g: 320,
    target_fat_g: 72,
    hydration_liters: 3.5,
    duration_days: 14,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '07:30',
        guidance: 'Protein-heavy breakfast supports muscle synthesis.',
        foods: [
          { food_name: 'Egg whites + whole eggs', portion: '4 whites + 2 whole', calories: 220, protein_g: 26, carbs_g: 2, fat_g: 12 },
          { food_name: 'Oats with milk', portion: '1 bowl', calories: 350, protein_g: 14, carbs_g: 48, fat_g: 10 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:00',
        guidance: 'Chicken + rice classic gym meal.',
        foods: [
          { food_name: 'Chicken curry', portion: '200 g chicken', calories: 380, protein_g: 48, carbs_g: 8, fat_g: 16 },
          { food_name: 'Jeera rice', portion: '1 katori', calories: 240, protein_g: 4, carbs_g: 50, fat_g: 4 },
        ],
      },
      {
        meal_label: 'Pre-workout',
        meal_time: '16:30',
        guidance: 'Easily digested carbs.',
        foods: [
          { food_name: 'Banana + whey (if used)', portion: '1 scoop + fruit', calories: 280, protein_g: 24, carbs_g: 32, fat_g: 3 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Lean fish or chicken with vegetables.',
        foods: [
          { food_name: 'Grilled fish', portion: '200 g', calories: 280, protein_g: 44, carbs_g: 0, fat_g: 10 },
          { food_name: 'Sweet potato', portion: '1 medium', calories: 180, protein_g: 3, carbs_g: 40, fat_g: 0 },
          { food_name: 'Vegetables', portion: '1 bowl', calories: 80, protein_g: 3, carbs_g: 14, fat_g: 2 },
        ],
      },
    ],
  },
  {
    key: 'healthy_veg',
    goal_key: 'healthy',
    dietary_preference: 'veg',
    base_calories: 2200,
    name: '7-Day Balanced Wellness (Veg)',
    description: 'Maintenance nutrition with whole foods and steady energy.',
    target_protein_g: 110,
    target_carbs_g: 260,
    target_fat_g: 65,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'Balanced macros; include fiber.',
        foods: [
          { food_name: 'Idli + sambar', portion: '3 idli + sambar', calories: 320, protein_g: 12, carbs_g: 58, fat_g: 4 },
          { food_name: 'Coconut chutney', portion: '2 tbsp', calories: 80, protein_g: 1, carbs_g: 4, fat_g: 7 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Rainbow plate: grains, dal, vegetables.',
        foods: [
          { food_name: 'Mixed dal', portion: '1 katori', calories: 160, protein_g: 10, carbs_g: 24, fat_g: 3 },
          { food_name: 'Roti', portion: '2', calories: 200, protein_g: 6, carbs_g: 38, fat_g: 4 },
          { food_name: 'Seasonal sabzi', portion: '1 bowl', calories: 120, protein_g: 4, carbs_g: 14, fat_g: 5 },
        ],
      },
      {
        meal_label: 'Snack',
        meal_time: '17:00',
        guidance: 'Whole food snack, not packaged junk.',
        foods: [
          { food_name: 'Fruit + nuts', portion: '1 fruit + 6 almonds', calories: 180, protein_g: 4, carbs_g: 24, fat_g: 8 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Light but satisfying dinner.',
        foods: [
          { food_name: 'Khichdi', portion: '1 bowl', calories: 320, protein_g: 12, carbs_g: 52, fat_g: 8 },
          { food_name: 'Curd', portion: '1/2 cup', calories: 70, protein_g: 5, carbs_g: 6, fat_g: 2 },
        ],
      },
    ],
  },
  {
    key: 'healthy_eggetarian',
    goal_key: 'healthy',
    dietary_preference: 'eggetarian',
    base_calories: 2200,
    name: '7-Day Balanced Wellness (Eggetarian)',
    description: 'Flexible maintenance plan with eggs and vegetarian meals.',
    target_protein_g: 115,
    target_carbs_g: 255,
    target_fat_g: 68,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'Eggs + whole grains.',
        foods: [
          { food_name: 'Boiled eggs', portion: '2', calories: 140, protein_g: 12, carbs_g: 1, fat_g: 10 },
          { food_name: 'Upma', portion: '1 bowl', calories: 280, protein_g: 8, carbs_g: 42, fat_g: 8 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Balanced Indian lunch plate.',
        foods: [
          { food_name: 'Dal tadka', portion: '1 katori', calories: 150, protein_g: 9, carbs_g: 20, fat_g: 4 },
          { food_name: 'Rice', portion: '1 katori', calories: 220, protein_g: 4, carbs_g: 48, fat_g: 1 },
          { food_name: 'Bhindi sabzi', portion: '1 bowl', calories: 110, protein_g: 3, carbs_g: 12, fat_g: 5 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Moderate portions; hydrate well.',
        foods: [
          { food_name: 'Vegetable pulao', portion: '1 plate', calories: 380, protein_g: 10, carbs_g: 58, fat_g: 12 },
          { food_name: 'Raita', portion: '1 bowl', calories: 90, protein_g: 4, carbs_g: 8, fat_g: 4 },
        ],
      },
    ],
  },
  {
    key: 'healthy_non_veg',
    goal_key: 'healthy',
    dietary_preference: 'non_veg',
    base_calories: 2200,
    name: '7-Day Balanced Wellness (Non-veg)',
    description: 'Maintenance plan with lean animal protein and whole grains.',
    target_protein_g: 120,
    target_carbs_g: 250,
    target_fat_g: 65,
    hydration_liters: 3,
    duration_days: 7,
    meals: [
      {
        meal_label: 'Breakfast',
        meal_time: '08:00',
        guidance: 'Lean protein to start the day.',
        foods: [
          { food_name: 'Egg white scramble', portion: '4 whites + 1 yolk', calories: 120, protein_g: 16, carbs_g: 2, fat_g: 6 },
          { food_name: 'Whole grain toast', portion: '2 slices', calories: 160, protein_g: 6, carbs_g: 28, fat_g: 3 },
        ],
      },
      {
        meal_label: 'Lunch',
        meal_time: '13:30',
        guidance: 'Grilled protein with complex carbs.',
        foods: [
          { food_name: 'Tandoori chicken', portion: '150 g', calories: 260, protein_g: 42, carbs_g: 4, fat_g: 8 },
          { food_name: 'Quinoa / brown rice', portion: '1 katori', calories: 200, protein_g: 5, carbs_g: 40, fat_g: 3 },
          { food_name: 'Salad', portion: '1 plate', calories: 50, protein_g: 2, carbs_g: 10, fat_g: 0 },
        ],
      },
      {
        meal_label: 'Dinner',
        meal_time: '20:00',
        guidance: 'Light fish dinner option.',
        foods: [
          { food_name: 'Grilled pomfret', portion: '150 g', calories: 220, protein_g: 34, carbs_g: 0, fat_g: 9 },
          { food_name: 'Steamed vegetables', portion: '1 bowl', calories: 80, protein_g: 3, carbs_g: 14, fat_g: 2 },
          { food_name: 'Roti', portion: '1', calories: 100, protein_g: 3, carbs_g: 19, fat_g: 2 },
        ],
      },
    ],
  },
];

function round1(value: number): number {
  return Math.round(value * 10) / 10;
}

function estimateCalories(
  goalKey: DietTemplate['goal_key'],
  weightKg?: number,
): number {
  if (weightKg && weightKg > 0) {
    switch (goalKey) {
      case 'weight_loss':
        return Math.max(1400, Math.round(weightKg * 24 - 400));
      case 'muscle_gain':
        return Math.round(weightKg * 30 + 300);
      default:
        return Math.round(weightKg * 26);
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

function estimateProtein(goalKey: DietTemplate['goal_key'], weightKg?: number, scaled?: number): number {
  if (weightKg && weightKg > 0) {
    const factor = goalKey === 'muscle_gain' ? 2.0 : goalKey === 'weight_loss' ? 2.0 : 1.4;
    return Math.round(weightKg * factor);
  }
  return Math.round(scaled ?? 120);
}

export function findTemplate(
  goalKey: DietTemplate['goal_key'],
  dietaryPreference: DietTemplate['dietary_preference'],
): DietTemplate {
  const exact = templates.find(
    (t) => t.goal_key === goalKey && t.dietary_preference === dietaryPreference,
  );
  if (exact) return exact;

  const sameGoal = templates.find((t) => t.goal_key === goalKey);
  if (sameGoal) return sameGoal;

  return templates[0];
}

export function generateFromTemplate(input: {
  goal_key: DietTemplate['goal_key'];
  dietary_preference?: DietTemplate['dietary_preference'];
  target_calories?: number;
  member_weight_kg?: number;
  cuisine_hint?: string;
}): DietPlanResult {
  const dietPref = input.dietary_preference ?? 'veg';
  const template = findTemplate(input.goal_key, dietPref);
  const targetCalories = input.target_calories ?? estimateCalories(input.goal_key, input.member_weight_kg);
  const factor = targetCalories / template.base_calories;

  const meals = template.meals.map((meal) => ({
    meal_label: meal.meal_label,
    meal_time: meal.meal_time,
    guidance: meal.guidance,
    foods: meal.foods.map((food) => ({
      food_name: food.food_name,
      portion: food.portion,
      calories: Math.max(1, Math.round(food.calories * factor)),
      protein_g: round1(food.protein_g * factor),
      carbs_g: round1(food.carbs_g * factor),
      fat_g: round1(food.fat_g * factor),
      notes: food.notes,
    })),
  }));

  const proteinTarget = estimateProtein(
    input.goal_key,
    input.member_weight_kg,
    template.target_protein_g * factor,
  );

  const cuisineNote = input.cuisine_hint?.trim();
  const description = cuisineNote
    ? `${template.description} Styled for: ${cuisineNote}.`
    : template.description;

  return {
    name: template.name.replace('7-Day', `${template.duration_days}-Day`),
    description,
    target_calories: targetCalories,
    target_protein_g: proteinTarget,
    target_carbs_g: round1(template.target_carbs_g * factor),
    target_fat_g: round1(template.target_fat_g * factor),
    hydration_liters: template.hydration_liters,
    duration_days: template.duration_days,
    meals,
  };
}
