import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';

List<Map<String, dynamic>> sortPaymentOptions(List<Map<String, dynamic>> rows) {
  final sorted = List<Map<String, dynamic>>.from(rows);
  sorted.sort((a, b) {
    final aPrimary = a['is_primary'] == true ? 0 : 1;
    final bPrimary = b['is_primary'] == true ? 0 : 1;
    if (aPrimary != bPrimary) return aPrimary - bPrimary;
    final aOrder = a['sort_order'] as int? ?? 0;
    final bOrder = b['sort_order'] as int? ?? 0;
    if (aOrder != bOrder) return aOrder - bOrder;
    return 0;
  });
  return sorted;
}

final gymPaymentOptionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, gymId) async {
  final rows = await ref.watch(gymRepositoryProvider).gymPaymentOptions(gymId);
  return sortPaymentOptions(rows);
});
