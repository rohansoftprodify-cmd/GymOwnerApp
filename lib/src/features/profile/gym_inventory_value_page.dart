import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/gym_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/subscription_plan_item.dart' show currencySymbol;

class GymInventoryValuePage extends ConsumerStatefulWidget {
  const GymInventoryValuePage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymInventoryValuePage> createState() => _GymInventoryValuePageState();
}

class _GymInventoryValuePageState extends ConsumerState<GymInventoryValuePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];
  String _currencySymbol = '₹';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final gym = await repo.gymById(widget.gymId);
      final rows = await repo.products(widget.gymId);
      if (!mounted) return;
      setState(() {
        _currencySymbol = currencySymbol(gym?['currency_code'] as String?);
        _products = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Valuation'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter products based on search query
    final filteredProducts = _products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final name = (p['name'] as String? ?? '').toLowerCase();
      final sku = (p['sku'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      return name.contains(query) || sku.contains(query);
    }).toList();

    // Calculate metrics based on ALL products (unfiltered)
    final totalUniqueProducts = _products.length;
    final totalStockQty = _products.fold<int>(0, (sum, p) {
      final qty = p['stock_qty'] as int? ?? 0;
      return sum + qty;
    });
    final totalInventoryValue = _products.fold<double>(0.0, (sum, p) {
      final qty = p['stock_qty'] as int? ?? 0;
      final price = GymRepository.productSellingPrice(p);
      return sum + (qty * price);
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inventory Valuation'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _load(showLoading: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showLoading: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // KPI metrics section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid / layout for the metrics cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  context,
                                  title: 'Unique Products',
                                  value: '$totalUniqueProducts',
                                  icon: Icons.category_outlined,
                                  iconColor: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  context,
                                  title: 'Total Stock Units',
                                  value: '$totalStockQty',
                                  icon: Icons.inventory_2_outlined,
                                  iconColor: semantics.accentCoral,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  context,
                                  title: 'Inventory Valuation',
                                  value: '$_currencySymbol${totalInventoryValue.toStringAsFixed(2)}',
                                  icon: Icons.monetization_on_outlined,
                                  iconColor: Colors.green,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildMetricCard(
                                context,
                                title: 'Unique Products',
                                value: '$totalUniqueProducts',
                                icon: Icons.category_outlined,
                                iconColor: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricCard(
                                context,
                                title: 'Total Stock Units',
                                value: '$totalStockQty',
                                icon: Icons.inventory_2_outlined,
                                iconColor: semantics.accentCoral,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricCard(
                                context,
                                title: 'Inventory Valuation',
                                value: '$_currencySymbol${totalInventoryValue.toStringAsFixed(2)}',
                                icon: Icons.monetization_on_outlined,
                                iconColor: Colors.green,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search products by name or SKU...',
                          hintStyle: TextStyle(color: semantics.mutedText, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            'Found ${filteredProducts.length} items',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: semantics.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Products List
            if (filteredProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No products matched "$_searchQuery"'
                              : 'No products in inventory.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: semantics.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filteredProducts[index];
                      final name = product['name'] as String? ?? '-';
                      final sku = product['sku'] as String?;
                      final stockQty = product['stock_qty'] as int? ?? 0;
                      final unitPrice = GymRepository.productSellingPrice(product);
                      final totalValue = stockQty * unitPrice;
                      final isActive = product['is_active'] as bool? ?? true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            decoration: isActive ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                        if (sku != null && sku.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: $sku',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: semantics.mutedText,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: semantics.mutedText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stock Qty',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: semantics.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            stockQty == 0
                                                ? Icons.warning_amber_rounded
                                                : Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: stockQty == 0
                                                ? semantics.accentCoral
                                                : Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$stockQty units',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: stockQty == 0 ? semantics.accentCoral : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Unit Price',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: semantics.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_currencySymbol${unitPrice.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock Value',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: semantics.mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_currencySymbol${totalValue.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                ),
              ),
            // Safe spacing at the bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: semantics.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
