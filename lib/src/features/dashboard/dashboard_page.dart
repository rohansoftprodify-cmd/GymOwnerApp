import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/attendance_tab.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/home_tab.dart';
import 'package:gym_owner_app/src/features/dashboard/tabs/products_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _index = 0;

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
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      Icon(
                        Icons.chevron_right_rounded,
                        color: semantics.mutedText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Logout?', style: TextStyle(fontSize: 18)),
                      content: const Text('Sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout != true) return;
                  await Supabase.instance.client.auth.signOut();
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
                    ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4))
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
                  height: 60,
                  selectedIndex: _index,
                  elevation: 0,
                  backgroundColor: semantics.cardBackground,
                  indicatorColor: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
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
