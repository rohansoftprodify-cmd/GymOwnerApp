import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/transactions/models/transaction_history_item.dart';
import 'package:gym_owner_app/src/features/transactions/widgets/transaction_tile.dart';
import 'package:intl/intl.dart';

enum _TransactionFilter { all, store, membership }

class TransactionsTab extends ConsumerStatefulWidget {
  const TransactionsTab({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  _TransactionFilter _filter = _TransactionFilter.all;
  int _reloadToken = 0;

  Future<List<TransactionHistoryItem>> _load() async {
    final rows = await ref.read(gymRepositoryProvider).transactionHistory(widget.gymId);
    return rows.map(_parseRow).toList();
  }

  TransactionHistoryItem _parseRow(Map<String, dynamic> row) {
    final kind = row['_kind'] as String? ?? '';
    if (kind == 'membership') {
      return TransactionHistoryItem.membership(row);
    }
    return TransactionHistoryItem.storeSale(row);
  }

  List<TransactionHistoryItem> _applyFilter(List<TransactionHistoryItem> items) {
    return switch (_filter) {
      _TransactionFilter.all => items,
      _TransactionFilter.store =>
        items.where((i) => i.kind == TransactionKind.storeSale).toList(),
      _TransactionFilter.membership =>
        items.where((i) => i.kind == TransactionKind.membership).toList(),
    };
  }

  double _sumAmount(Iterable<TransactionHistoryItem> items) =>
      items.fold<double>(0, (sum, item) => sum + item.amount);

  Map<String, List<TransactionHistoryItem>> _groupByDay(List<TransactionHistoryItem> items) {
    final map = <String, List<TransactionHistoryItem>>{};
    final dayFormat = DateFormat.yMMMEd();
    for (final item in items) {
      final key = dayFormat.format(item.occurredAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<TransactionHistoryItem>>(
      key: ValueKey(_reloadToken),
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snap.data!;
        final filtered = _applyFilter(allItems);
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final monthStart = DateTime(now.year, now.month, 1);

        final todayItems = allItems.where((i) => !i.occurredAt.isBefore(todayStart));
        final monthItems = allItems.where((i) => !i.occurredAt.isBefore(monthStart));
        final grouped = _groupByDay(filtered);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _reloadToken++);
            await _load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100, top: 4),
            children: [
              _SummaryStrip(
                todayTotal: _sumAmount(todayItems),
                monthTotal: _sumAmount(monthItems),
                transactionCount: allItems.length,
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _TransactionFilter.all,
                      onTap: () => setState(() => _filter = _TransactionFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Store sales',
                      selected: _filter == _TransactionFilter.store,
                      onTap: () => setState(() => _filter = _TransactionFilter.store),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Memberships',
                      selected: _filter == _TransactionFilter.membership,
                      onTap: () => setState(() => _filter = _TransactionFilter.membership),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: semantics.mutedText.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Store sales and new membership records appear here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                      ),
                    ],
                  ),
                )
              else
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(
                          '₹${NumberFormat('#,##0').format(_sumAmount(entry.value).round())}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: semantics.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final item in entry.value) TransactionTile(item: item),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.todayTotal,
    required this.monthTotal,
    required this.transactionCount,
  });

  final double todayTotal;
  final double monthTotal;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final money = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transaction history',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Today',
                  value: '₹${money.format(todayTotal.round())}',
                  color: colorScheme.onPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colorScheme.onPrimary.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'This month',
                  value: '₹${money.format(monthTotal.round())}',
                  color: colorScheme.onPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colorScheme.onPrimary.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Records',
                  value: '$transactionCount',
                  color: semantics.accentLime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      checkmarkColor: colorScheme.primary,
    );
  }
}
