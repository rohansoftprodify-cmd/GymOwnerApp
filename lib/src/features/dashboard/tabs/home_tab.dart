import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/dashboard_sheets.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/fee_horizontal_list.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/offers_carousel.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/churn_radar_section.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/overview_card.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(gymRepositoryProvider);
    final aiRepo = ref.watch(aiRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        repo.members(gymId),
        repo.attendance(gymId),
        repo.subscriptions(gymId),
        repo.products(gymId),
        repo.activePromotions(gymId),
        repo.promotions(gymId),
        repo.reports(gymId),
        aiRepo.getChurnRisks(gymId),
      ]),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final members = snap.data![0] as List<Map<String, dynamic>>;
        final attendance = snap.data![1] as List<Map<String, dynamic>>;
        final subscriptions = snap.data![2] as List<Map<String, dynamic>>;
        final products = snap.data![3] as List<Map<String, dynamic>>;
        final activePromotions = snap.data![4] as List<Map<String, dynamic>>;
        final allPromotions = snap.data![5] as List<Map<String, dynamic>>;
        final reports = snap.data![6] as Map<String, dynamic>;
        final churnRisks = snap.data![7] as ChurnRiskResult;
        final dues = reports['dues'] as Map<String, dynamic>?;
        final pendingAmount = dues?['pending_amount'] ?? 0;

        final now = DateTime.now();
        final upcomingCutoff = now.add(const Duration(days: 15));
        final pendingFees = subscriptions.where((s) {
          final status = (s['payment_status'] as String? ?? '').toLowerCase();
          return status == 'due' || status == 'partial';
        }).toList();
        final upcomingRenewals =
            subscriptions.where((s) {
              final raw = s['end_date'] as String?;
              if (raw == null) return false;
              final endDate = DateTime.tryParse(raw);
              if (endDate == null) return false;
              return endDate.isAfter(now.subtract(const Duration(days: 1))) &&
                  endDate.isBefore(upcomingCutoff);
            }).toList()..sort(
              (a, b) =>
                  (a['end_date'] as String).compareTo(b['end_date'] as String),
            );

        final todayAttendance = attendance.where((row) {
          final raw = row['check_in_at'] as String?;
          final time = raw == null ? null : DateTime.tryParse(raw);
          if (time == null) return false;
          return time.year == now.year &&
              time.month == now.month &&
              time.day == now.day;
        }).length;

        final colorScheme = theme.colorScheme;
        final semantics = context.appColors;
        final primary = colorScheme.primary;

        return ListView(
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.show_chart_rounded,
                  color: semantics.mutedText,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Members',
                    value: '${members.length}',
                    icon: Icons.people_alt_rounded,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OverviewCard(
                    title: 'Check-ins',
                    value: '$todayAttendance',
                    icon: Icons.how_to_reg_rounded,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Products',
                    value: '${products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OverviewCard(
                    title: 'Overdue',
                    value: '₹$pendingAmount',
                    icon: Icons.account_balance_wallet_outlined,
                    color: semantics.accentCoral,
                  ),
                ),
              ],
            ),
            ChurnRadarSection(gymId: gymId, result: churnRisks),
            if (activePromotions.isNotEmpty) ...[
              const SizedBox(height: 4),
              SectionHeader(
                title: 'Exclusive Offers',
                actionLabel: 'View All',
                onAction: () => showPromotionsSheet(context, allPromotions),
              ),
              const SizedBox(height: 4),
              OffersCarousel(promotions: activePromotions),
            ],
            if (pendingFees.isNotEmpty) ...[
              const SizedBox(height: 4),
              SectionHeader(
                title: 'Pending Fees',
                actionLabel: 'Details',
                onAction: () =>
                    showFeeListSheet(context, pendingFees, 'Pending Fees'),
              ),
              const SizedBox(height: 4),
              FeeHorizontalList(
                items: pendingFees,
                emptyText: 'No pending fees.',
                mode: FeeListMode.pendingFees,
              ),
            ],
            if (upcomingRenewals.isNotEmpty) ...[
              const SizedBox(height: 4),
              SectionHeader(
                title: 'Renewals',
                actionLabel: 'Full List',
                onAction: () => showFeeListSheet(
                  context,
                  upcomingRenewals,
                  'Upcoming Renewals',
                  mode: FeeListMode.renewals,
                ),
              ),
              const SizedBox(height: 4),
              FeeHorizontalList(
                items: upcomingRenewals,
                emptyText: 'No renewals due.',
                mode: FeeListMode.renewals,
              ),
            ],
          ],
        );
      },
    );
  }
}
