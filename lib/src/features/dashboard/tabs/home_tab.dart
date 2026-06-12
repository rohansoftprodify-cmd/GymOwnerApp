import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/ai/models/sales_forecast_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/churn_radar_section.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/dashboard_sheets.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/fee_horizontal_list.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/home_pulse_card.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/home_quick_actions.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/home_welcome_banner.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/offers_carousel.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/overview_card.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/sales_forecast_section.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';
import 'package:intl/intl.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  static const _sectionGap = 20.0;
  int _refreshTick = 0;

  Future<List<dynamic>> _loadHomeData() {
    final repo = ref.read(gymRepositoryProvider);
    final aiRepo = ref.read(aiRepositoryProvider);
    return Future.wait<dynamic>([
      repo.members(widget.gymId),
      repo.attendance(widget.gymId),
      repo.subscriptions(widget.gymId),
      repo.products(widget.gymId),
      repo.activePromotions(widget.gymId),
      repo.promotions(widget.gymId),
      repo.reports(widget.gymId),
      aiRepo.getChurnRisks(widget.gymId),
      aiRepo.getSalesForecast(widget.gymId),
    ]);
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final tenant = ref.watch(tenantContextProvider).valueOrNull;
    final gymName = tenant?.gymName ?? 'Your gym';
    final role = tenant?.role ?? 'owner';

    return FutureBuilder<List<dynamic>>(
      key: ValueKey(_refreshTick),
      future: _loadHomeData(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snap.data![0] as List<Map<String, dynamic>>;
        final attendance = snap.data![1] as List<Map<String, dynamic>>;
        final subscriptions = snap.data![2] as List<Map<String, dynamic>>;
        final products = snap.data![3] as List<Map<String, dynamic>>;
        final activePromotions = snap.data![4] as List<Map<String, dynamic>>;
        final allPromotions = snap.data![5] as List<Map<String, dynamic>>;
        final reports = snap.data![6] as Map<String, dynamic>;
        final churnRisks = snap.data![7] as ChurnRiskResult;
        final salesForecast = snap.data![8] as SalesForecastResult;
        final dues = reports['dues'] as Map<String, dynamic>?;
        final pendingAmount = dues?['pending_amount'] ?? 0;

        final now = DateTime.now();
        final upcomingCutoff = now.add(const Duration(days: 15));
        final pendingFees = subscriptions.where((s) {
          final status = (s['payment_status'] as String? ?? '').toLowerCase();
          return status == 'due' || status == 'partial';
        }).toList();
        final upcomingRenewals = subscriptions.where((s) {
          final raw = s['end_date'] as String?;
          if (raw == null) return false;
          final endDate = DateTime.tryParse(raw);
          if (endDate == null) return false;
          return endDate.isAfter(now.subtract(const Duration(days: 1))) &&
              endDate.isBefore(upcomingCutoff);
        }).toList()
          ..sort((a, b) => (a['end_date'] as String).compareTo(b['end_date'] as String));

        final todayAttendance = attendance.where((row) {
          final raw = row['check_in_at'] as String?;
          final time = raw == null ? null : DateTime.tryParse(raw);
          if (time == null) return false;
          return time.year == now.year &&
              time.month == now.month &&
              time.day == now.day;
        }).length;

        final activePlans = subscriptions.where((s) {
          final status = (s['status'] as String? ?? '').toLowerCase();
          return status == 'active';
        }).length;

        final money = NumberFormat('#,##0').format(pendingAmount);

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100, top: 4),
            children: [
              // HomeWelcomeBanner(
              //   gymName: gymName,
              //   role: role,
              //   onTap: () => context.push('/gym-profile?gymId=${widget.gymId}'),
              // ),
              const SizedBox(height: 14),
              HomeQuickActions(
                actions: [
                  HomeQuickAction(
                    icon: Icons.people_alt_rounded,
                    label: 'Members',
                    onTap: () => context.push('/members?gymId=${widget.gymId}'),
                  ),
                  HomeQuickAction(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Check-in QR',
                    onTap: () => context.push('/gym-check-in-qr?gymId=${widget.gymId}'),
                  ),
                  HomeQuickAction(
                    icon: Icons.insights_rounded,
                    label: 'Retention',
                    accentColor: semantics.accentCoral,
                    onTap: () => context.push('/member-retention?gymId=${widget.gymId}'),
                  ),
                  HomeQuickAction(
                    icon: Icons.support_agent_rounded,
                    label: 'Support',
                    onTap: () => context.push('/support-faqs?gymId=${widget.gymId}'),
                  ),
                ],
              ),
              const SizedBox(height: _sectionGap),
              HomePulseCard(
                checkInsToday: todayAttendance,
                activeMembers: activePlans,
                pendingFeesCount: pendingFees.length,
              ),
              const SizedBox(height: _sectionGap),
              _SectionLabel(
                title: 'Gym snapshot',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OverviewCard(
                      title: 'Total members',
                      value: '${members.length}',
                      icon: Icons.people_alt_rounded,
                      color: colorScheme.primary,
                      subtitle: '$activePlans active plans',
                      onTap: () => context.push('/members?gymId=${widget.gymId}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OverviewCard(
                      title: 'Store items',
                      value: '${products.length}',
                      icon: Icons.inventory_2_outlined,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OverviewCard(
                      title: 'Overdue fees',
                      value: '₹$money',
                      icon: Icons.account_balance_wallet_outlined,
                      color: semantics.accentCoral,
                      subtitle: pendingFees.isEmpty
                          ? 'All clear'
                          : '${pendingFees.length} pending',
                      onTap: pendingFees.isEmpty
                          ? null
                          : () => showFeeListSheet(context, pendingFees, 'Pending Fees'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OverviewCard(
                      title: 'Renewals (15d)',
                      value: '${upcomingRenewals.length}',
                      icon: Icons.event_available_rounded,
                      color: semantics.accentLime,
                      subtitle: upcomingRenewals.isEmpty ? 'None due soon' : 'Upcoming',
                      onTap: upcomingRenewals.isEmpty
                          ? null
                          : () => showFeeListSheet(
                                context,
                                upcomingRenewals,
                                'Upcoming Renewals',
                                mode: FeeListMode.renewals,
                              ),
                    ),
                  ),
                ],
              ),
              ChurnRadarSection(gymId: widget.gymId, result: churnRisks),
              SalesForecastSection(gymId: widget.gymId, result: salesForecast),
              if (activePromotions.isNotEmpty) ...[
                const SizedBox(height: 4),
                SectionHeader(
                  title: 'Exclusive offers',
                  actionLabel: 'View all',
                  onAction: () => showPromotionsSheet(context, allPromotions),
                ),
                const SizedBox(height: 6),
                OffersCarousel(promotions: activePromotions),
              ],
              if (pendingFees.isNotEmpty) ...[
                const SizedBox(height: 4),
                SectionHeader(
                  title: 'Pending fees',
                  actionLabel: 'Details',
                  onAction: () => showFeeListSheet(context, pendingFees, 'Pending Fees'),
                ),
                const SizedBox(height: 6),
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
                  actionLabel: 'Full list',
                  onAction: () => showFeeListSheet(
                    context,
                    upcomingRenewals,
                    'Upcoming Renewals',
                    mode: FeeListMode.renewals,
                  ),
                ),
                const SizedBox(height: 6),
                FeeHorizontalList(
                  items: upcomingRenewals,
                  emptyText: 'No renewals due.',
                  mode: FeeListMode.renewals,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          'Pull to refresh',
          style: theme.textTheme.labelSmall?.copyWith(
            color: semantics.mutedText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
