export type WorkoutExercise = {
  exercise_name: string;
  sets: number;
  reps: number;
  rest_seconds?: number;
  notes?: string;
};

export type WorkoutSession = {
  day_label: string;
  day_number: number;
  guidance?: string;
  exercises: WorkoutExercise[];
};

export type WorkoutPlanResult = {
  name: string;
  description: string;
  duration_weeks: number;
  sessions_per_week: number;
  experience_level: string;
  equipment_hint?: string;
  sessions: WorkoutSession[];
};

type TemplateRow = WorkoutPlanResult & {
  key: string;
  goal_key: string;
};

const templates: TemplateRow[] = [
  {
    key: 'muscle_gain_beginner_dumbbells_4',
    goal_key: 'muscle_gain',
    experience_level: 'beginner',
    equipment_hint: 'dumbbells only',
    sessions_per_week: 4,
    duration_weeks: 4,
    name: '4-Day Muscle Gain (Beginner · Dumbbells)',
    description:
      'Full-body split using dumbbells only. Focus on form, progressive overload, and 48h recovery between muscle groups.',
    sessions: [
      {
        day_label: 'Day 1 — Push',
        day_number: 1,
        guidance: 'Warm up 5 min. Rest 60–90s between sets.',
        exercises: [
          { exercise_name: 'Goblet squat', sets: 3, reps: 12, rest_seconds: 90 },
          { exercise_name: 'Dumbbell bench press', sets: 3, reps: 10, rest_seconds: 90 },
          { exercise_name: 'Dumbbell shoulder press', sets: 3, reps: 10, rest_seconds: 90 },
          { exercise_name: 'Dumbbell tricep kickback', sets: 3, reps: 12, rest_seconds: 60 },
        ],
      },
      {
        day_label: 'Day 2 — Pull',
        day_number: 2,
        guidance: 'Control the eccentric on rows.',
        exercises: [
          { exercise_name: 'Dumbbell Romanian deadlift', sets: 3, reps: 10, rest_seconds: 90 },
          { exercise_name: 'One-arm dumbbell row', sets: 3, reps: 10, rest_seconds: 90 },
          { exercise_name: 'Dumbbell bicep curl', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Dumbbell hammer curl', sets: 3, reps: 12, rest_seconds: 60 },
        ],
      },
      {
        day_label: 'Day 3 — Legs',
        day_number: 3,
        guidance: 'Keep core braced on lunges.',
        exercises: [
          { exercise_name: 'Dumbbell walking lunge', sets: 3, reps: 10, rest_seconds: 90 },
          { exercise_name: 'Dumbbell sumo squat', sets: 3, reps: 12, rest_seconds: 90 },
          { exercise_name: 'Dumbbell calf raise', sets: 4, reps: 15, rest_seconds: 45 },
          { exercise_name: 'Dumbbell glute bridge', sets: 3, reps: 15, rest_seconds: 60 },
        ],
      },
      {
        day_label: 'Day 4 — Upper pump',
        day_number: 4,
        guidance: 'Lighter weight, higher reps.',
        exercises: [
          { exercise_name: 'Dumbbell floor press', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Dumbbell lateral raise', sets: 3, reps: 15, rest_seconds: 60 },
          { exercise_name: 'Dumbbell reverse fly', sets: 3, reps: 15, rest_seconds: 60 },
          { exercise_name: 'Dumbbell plank row', sets: 3, reps: 10, rest_seconds: 60 },
        ],
      },
    ],
  },
  {
    key: 'weight_loss_beginner_full_gym_3',
    goal_key: 'weight_loss',
    experience_level: 'beginner',
    equipment_hint: 'full gym',
    sessions_per_week: 3,
    duration_weeks: 4,
    name: '3-Day Fat Loss Circuit (Beginner)',
    description: 'Compound movements with short rest for calorie burn.',
    sessions: [
      {
        day_label: 'Day 1 — Full body A',
        day_number: 1,
        exercises: [
          { exercise_name: 'Leg press', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Lat pulldown', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Chest press machine', sets: 3, reps: 12, rest_seconds: 60 },
        ],
      },
      {
        day_label: 'Day 2 — Cardio + core',
        day_number: 2,
        exercises: [
          { exercise_name: 'Stationary bike', sets: 1, reps: 20, notes: '20 min moderate' },
          { exercise_name: 'Plank', sets: 3, reps: 45, notes: '45 sec hold' },
        ],
      },
      {
        day_label: 'Day 3 — Full body B',
        day_number: 3,
        exercises: [
          { exercise_name: 'Goblet squat', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Seated row', sets: 3, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Dumbbell shoulder press', sets: 3, reps: 10, rest_seconds: 60 },
        ],
      },
    ],
  },
  {
    key: 'healthy_intermediate_bodyweight_3',
    goal_key: 'healthy',
    experience_level: 'intermediate',
    equipment_hint: 'bodyweight only',
    sessions_per_week: 3,
    duration_weeks: 4,
    name: '3-Day Bodyweight Maintenance',
    description: 'Balanced strength and mobility without equipment.',
    sessions: [
      {
        day_label: 'Day 1 — Strength',
        day_number: 1,
        exercises: [
          { exercise_name: 'Push-up', sets: 4, reps: 12, rest_seconds: 60 },
          { exercise_name: 'Bodyweight squat', sets: 4, reps: 15, rest_seconds: 60 },
          { exercise_name: 'Glute bridge', sets: 3, reps: 15, rest_seconds: 45 },
        ],
      },
      {
        day_label: 'Day 2 — Mobility',
        day_number: 2,
        exercises: [
          { exercise_name: 'Cat-cow stretch', sets: 2, reps: 10, rest_seconds: 30 },
          { exercise_name: 'Hip flexor stretch', sets: 2, reps: 45, notes: 'each side' },
        ],
      },
      {
        day_label: 'Day 3 — Conditioning',
        day_number: 3,
        exercises: [
          { exercise_name: 'Jumping jack', sets: 3, reps: 30, rest_seconds: 45 },
          { exercise_name: 'Mountain climber', sets: 3, reps: 20, rest_seconds: 45 },
          { exercise_name: 'Walking lunge', sets: 3, reps: 12, rest_seconds: 60 },
        ],
      },
    ],
  },
];

function normalizeEquipment(hint?: string): string {
  return (hint ?? '').toLowerCase().trim();
}

function findTemplate(input: {
  goal_key: string;
  experience_level?: string;
  equipment_hint?: string;
  sessions_per_week?: number;
}): TemplateRow {
  const goal = input.goal_key;
  const level = input.experience_level ?? 'beginner';
  const equipment = normalizeEquipment(input.equipment_hint);
  const spw = input.sessions_per_week;

  const scored = templates
    .filter((t) => t.goal_key === goal)
    .map((t) => {
      let score = 0;
      if (t.experience_level === level) score += 3;
      if (spw && t.sessions_per_week === spw) score += 2;
      if (equipment && normalizeEquipment(t.equipment_hint).includes(equipment)) score += 4;
      if (equipment && equipment.includes('dumbbell') && t.equipment_hint?.includes('dumbbell')) score += 5;
      return { t, score };
    })
    .sort((a, b) => b.score - a.score);

  if (scored.length > 0 && scored[0].score > 0) return scored[0].t;

  const byGoal = templates.find((t) => t.goal_key === goal);
  return byGoal ?? templates[0];
}

export function generateFromTemplate(input: {
  goal_key: string;
  experience_level?: string;
  equipment_hint?: string;
  sessions_per_week?: number;
  duration_weeks?: number;
  member_age?: number;
  member_weight_kg?: number;
}): WorkoutPlanResult {
  const template = findTemplate(input);
  const durationWeeks = input.duration_weeks ?? template.duration_weeks;
  const sessionsPerWeek = input.sessions_per_week ?? template.sessions_per_week;

  let description = template.description;
  if (input.member_age) description += ` Tailored for age ${input.member_age}.`;
  if (input.member_weight_kg) description += ` Member weight: ${input.member_weight_kg} kg.`;

  return {
    name: template.name.replace(/\d-Day/, `${sessionsPerWeek}-Day`),
    description,
    duration_weeks: durationWeeks,
    sessions_per_week: sessionsPerWeek,
    experience_level: input.experience_level ?? template.experience_level,
    equipment_hint: input.equipment_hint ?? template.equipment_hint,
    sessions: template.sessions.map((s, i) => ({
      ...s,
      day_number: i + 1,
      exercises: s.exercises.map((e) => ({ ...e })),
    })),
  };
}
