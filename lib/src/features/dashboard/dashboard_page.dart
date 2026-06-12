import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/auth/single_session_provider.dart';
import 'package:gym_owner_app/src/core/tenant/gym_setup_provider.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/attendance_tab.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/home_tab.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/products_tab.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/transactions_tab.dart';
import 'package:gym_owner_app/src/features/payments/gym_payment_qr_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _index = 0;
  bool _redirectedToLogin = false;
  bool _redirectedToSetup = false;

  static const _navItems =
      <({String label, IconData icon, IconData selectedIcon})>[
        (
          label: 'Home',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
        ),
        (
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
        ),
        (
          label: 'Store',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
        ),
        (
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
      ];

  void _scheduleRedirect(
    VoidCallback redirect, {
    required bool Function() alreadyRedirected,
    required void Function(bool) setRedirected,
  }) {
    if (alreadyRedirected()) return;
    setRedirected(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      redirect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<AsyncValue<bool>>(gymOwnerSetupRequiredProvider, (
      previous,
      next,
    ) {
      final required = next.value;
      if (required == true) {
        _scheduleRedirect(
          () => context.go('/owner-setup'),
          alreadyRedirected: () => _redirectedToSetup,
          setRedirected: (v) => _redirectedToSetup = v,
        );
      } else if (required == false) {
        _redirectedToSetup = false;
      }
    });

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _scheduleRedirect(
        () => context.go('/login'),
        alreadyRedirected: () => _redirectedToLogin,
        setRedirected: (v) => _redirectedToLogin = v,
      );
      return const SizedBox.shrink();
    }
    _redirectedToLogin = false;

    final setupRequiredAsync = ref.watch(gymOwnerSetupRequiredProvider);
    if (setupRequiredAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (setupRequiredAsync.value == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tenantAsync = ref.watch(tenantContextProvider);
    return tenantAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text(err.toString()))),
      data: (tenant) {
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('No gym assigned')),
            body: const Center(
              child: Text('Assign a role in gym_roles to continue.'),
            ),
          );
        }

        final pages = [
          HomeTab(gymId: tenant.gymId),
          AttendanceTab(gymId: tenant.gymId),
          ProductsTab(gymId: tenant.gymId),
          TransactionsTab(gymId: tenant.gymId),
        ];

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: 64,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleSpacing: 16,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            title: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/gym-profile?gymId=${tenant.gymId}'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const AppLogo(size: 40, borderRadius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.gymName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: semantics.accentLime,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tenant.role.toUpperCase(),
                                style: TextStyle(
                                  color: semantics.onAccentLime,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icon(
                      //   Icons.chevron_right_rounded,
                      //   color: semantics.mutedText,
                      //   size: 22,
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Payment QR',
                onPressed: () => showGymPaymentQrBottomSheet(
                  context,
                  gymId: tenant.gymId,
                ),
                icon: Icon(
                  Icons.qr_code_2_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text(
                        'Logout?',
                        style: TextStyle(fontSize: 18),
                      ),
                      content: const Text('Sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout != true) return;
                  await ref.read(singleSessionServiceProvider).signOutLocally();
                  if (context.mounted) context.go('/login');
                },
                icon: Icon(
                  Icons.logout_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: pages[_index],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: semantics.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: isDark
                    ? Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      )
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: NavigationBar(
                  height: 64,
                  selectedIndex: _index,
                  elevation: 0,
                  backgroundColor: semantics.cardBackground,
                  indicatorColor: colorScheme.primary.withValues(
                    alpha: isDark ? 0.22 : 0.14,
                  ),
                  surfaceTintColor: Colors.transparent,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final item in _navItems)
                      NavigationDestination(
                        icon: Icon(item.icon, size: 22),
                        selectedIcon: Icon(item.selectedIcon, size: 22),
                        label: item.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
