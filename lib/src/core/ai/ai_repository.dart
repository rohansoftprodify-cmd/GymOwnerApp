import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';
import 'package:gym_owner_app/src/features/ai/models/attendance_analytics_result.dart';
import 'package:gym_owner_app/src/features/ai/models/sales_forecast_result.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/ai/models/diet_ai_quota.dart';
import 'package:gym_owner_app/src/features/ai/models/gym_analysis_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DietPlanGenerateMode { template, ai, quota }

enum WorkoutPlanGenerateMode { template, ai, quota, adjust }

enum MarketingGenerateMode { template, ai }

class AiRepository {
  AiRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> generateDietPlan({
    required String gymId,
    required String goalKey,
    DietPlanGenerateMode mode = DietPlanGenerateMode.template,
    int? targetCalories,
    String dietaryPreference = 'veg',
    double? memberWeightKg,
    String? cuisineHint,
  }) async {
    final response = await _client.functions.invoke(
      'ai-generate-diet-plan',
      body: {
        'gym_id': gymId,
        'goal_key': goalKey,
        'mode': switch (mode) {
          DietPlanGenerateMode.template => 'template',
          DietPlanGenerateMode.ai => 'ai',
          DietPlanGenerateMode.quota => 'quota',
        },
        if (targetCalories != null) 'target_calories': targetCalories,
        'dietary_preference': dietaryPreference,
        if (memberWeightKg != null) 'member_weight_kg': memberWeightKg,
        if (cuisineHint != null && cuisineHint.trim().isNotEmpty)
          'cuisine_hint': cuisineHint.trim(),
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map) {
      final message = data is Map
          ? data['error']?.toString() ?? 'Diet plan generation failed.'
          : 'Diet plan generation failed.';
      throw Exception(message);
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> generateMarketingContent({
    required String gymId,
    required String contentType,
    required String prompt,
    MarketingGenerateMode mode = MarketingGenerateMode.ai,
    String? offerHint,
    String? memberName,
  }) async {
    final response = await _client.functions.invoke(
      'ai-generate-marketing',
      body: {
        'gym_id': gymId,
        'content_type': contentType,
        'prompt': prompt,
        'mode': mode == MarketingGenerateMode.template ? 'template' : 'ai',
        if (offerHint != null && offerHint.trim().isNotEmpty) 'offer_hint': offerHint.trim(),
        if (memberName != null && memberName.trim().isNotEmpty) 'member_name': memberName.trim(),
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map) {
      final message = data is Map
          ? data['error']?.toString() ?? 'Marketing generation failed.'
          : 'Marketing generation failed.';
      throw Exception(message);
    }
    return Map<String, dynamic>.from(data);
  }

  Future<DietAiQuota> getMarketingAiQuota(String gymId) async {
    try {
      final response = await _client.rpc('get_gym_ai_marketing_quota', params: {
        'p_gym_id': gymId,
      });
      if (response is Map) {
        return DietAiQuota.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Migration may not be applied yet.
    }
    return const DietAiQuota(used: 0, limit: 10, remaining: 10);
  }

  Future<DietAiQuota> getDietAiQuota(String gymId) async {
    try {
      final response = await _client.rpc('get_gym_ai_diet_quota', params: {
        'p_gym_id': gymId,
      });
      if (response is Map) {
        return DietAiQuota.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Migration may not be applied yet.
    }

    return const DietAiQuota(used: 0, limit: 5, remaining: 5);
  }

  Future<GymAnalysisResult> getGymAnalysis(String gymId, {int months = 12}) async {
    try {
      final response = await _client.rpc('get_gym_ai_analysis', params: {
        'p_gym_id': gymId,
        'p_months': months,
      });
      if (response is Map) {
        return GymAnalysisResult.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Migration may not be applied yet.
    }
    return GymAnalysisResult(
      summary: 'Analysis will appear after you apply the latest database migration.',
      membership: const GymMembershipAnalysis(),
      sales: const GymSalesAnalysis(),
      attendance: const GymAttendanceAnalysis(),
      members: const GymMembersAnalysis(),
      insights: const [],
      periodMonths: months,
    );
  }

  Future<AttendanceAnalyticsResult> getAttendanceAnalytics(
    String gymId, {
    int days = 30,
  }) async {
    try {
      final response = await _client.rpc('get_gym_attendance_analytics', params: {
        'p_gym_id': gymId,
        'p_days': days,
      });
      if (response is Map) {
        return AttendanceAnalyticsResult.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Migration may not be applied yet.
    }
    return AttendanceAnalyticsResult(
      summary: 'Attendance analytics will appear after you apply the latest database migration.',
      overview: const AttendanceOverview(),
      peakHours: const [],
      quietHours: const [],
      equipmentPressure: const EquipmentPressureAnalysis(),
      dayOfWeek: const [],
      weekendVsWeekday: const WeekendWeekdaySplit(),
      checkInMethods: const [],
      insights: const [],
      periodDays: days,
    );
  }

  Future<SalesForecastResult> getSalesForecast(
    String gymId, {
    int forecastMonths = 3,
  }) async {
    try {
      final response = await _client.rpc('get_gym_sales_forecast', params: {
        'p_gym_id': gymId,
        'p_forecast_months': forecastMonths,
      });
      if (response is Map) {
        return SalesForecastResult.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // Migration may not be applied yet.
    }
    return SalesForecastResult(
      summary: 'Sales forecast will appear after you apply the latest database migration.',
      overview: const SalesForecastOverview(),
      monthlyHistory: const [],
      monthlyForecast: const [],
      renewals: const RenewalsForecast(),
      churn: const ChurnForecast(),
      staffingHints: const StaffingHints(),
      insights: const [],
      forecastMonths: forecastMonths,
    );
  }

  Future<Map<String, dynamic>> generateWorkoutPlan({
    required String gymId,
    required String goalKey,
    WorkoutPlanGenerateMode mode = WorkoutPlanGenerateMode.template,
    String experienceLevel = 'beginner',
    String? equipmentHint,
    int? sessionsPerWeek,
    int? durationWeeks,
    int? memberAge,
    double? memberWeightKg,
    String? workoutPlanId,
    Map<String, dynamic>? currentPlan,
    String? completionSummary,
  }) async {
    final response = await _client.functions.invoke(
      'ai-generate-workout-plan',
      body: {
        'gym_id': gymId,
        'goal_key': goalKey,
        'mode': switch (mode) {
          WorkoutPlanGenerateMode.template => 'template',
          WorkoutPlanGenerateMode.ai => 'ai',
          WorkoutPlanGenerateMode.quota => 'quota',
          WorkoutPlanGenerateMode.adjust => 'adjust',
        },
        'experience_level': experienceLevel,
        if (equipmentHint != null && equipmentHint.trim().isNotEmpty)
          'equipment_hint': equipmentHint.trim(),
        if (sessionsPerWeek != null) 'sessions_per_week': sessionsPerWeek,
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
        if (memberAge != null) 'member_age': memberAge,
        if (memberWeightKg != null) 'member_weight_kg': memberWeightKg,
        if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
        if (currentPlan != null) 'current_plan': currentPlan,
        if (completionSummary != null) 'completion_summary': completionSummary,
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map) {
      final message = data is Map
          ? data['error']?.toString() ?? 'Workout plan generation failed.'
          : 'Workout plan generation failed.';
      throw Exception(message);
    }
    return Map<String, dynamic>.from(data);
  }

  Future<DietAiQuota> getWorkoutAiQuota(String gymId) async {
    try {
      final response = await _client.rpc('get_gym_ai_workout_quota', params: {
        'p_gym_id': gymId,
      });
      if (response is Map) {
        return DietAiQuota.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return const DietAiQuota(used: 0, limit: 5, remaining: 5);
  }

  Future<ChurnRiskResult> getChurnRisks(String gymId) async {
    try {
      final response = await _client.rpc('get_gym_churn_risks', params: {
        'p_gym_id': gymId,
      });
      if (response is! Map) {
        return const ChurnRiskResult(members: [], summary: ChurnRiskSummary());
      }
      return ChurnRiskResult.fromMap(Map<String, dynamic>.from(response));
    } catch (_) {
      return const ChurnRiskResult(members: [], summary: ChurnRiskSummary());
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(supabaseClientProvider));
});

final gymAnalysisProvider =
    FutureProvider.family<GymAnalysisResult, String>((ref, gymId) {
  return ref.watch(aiRepositoryProvider).getGymAnalysis(gymId);
});

final attendanceAnalyticsProvider =
    FutureProvider.family<AttendanceAnalyticsResult, String>((ref, gymId) {
  return ref.watch(aiRepositoryProvider).getAttendanceAnalytics(gymId);
});

final salesForecastProvider =
    FutureProvider.family<SalesForecastResult, String>((ref, gymId) {
  return ref.watch(aiRepositoryProvider).getSalesForecast(gymId);
});

final memberRetentionProvider =
    FutureProvider.family<ChurnRiskResult, String>((ref, gymId) {
  return ref.watch(aiRepositoryProvider).getChurnRisks(gymId);
});
