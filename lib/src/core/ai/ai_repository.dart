import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/ai/models/diet_ai_quota.dart';
import 'package:gym_owner_app/src/features/ai/models/gym_analysis_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DietPlanGenerateMode { template, ai, quota }

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
