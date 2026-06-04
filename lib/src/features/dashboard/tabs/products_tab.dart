import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  String? _selectedCategoryId;
  int _reloadToken = 0;

  void _refresh() => setState(() => _reloadToken++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(gymRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_reloadToken),
        future: Future.wait<dynamic>([
          repo.categories(widget.gymId),
          repo.products(widget.gymId, categoryId: _selectedCategoryId),
        ]),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snap.data![0] as List<Map<String, dynamic>>;
          final products = snap.data![1] as List<Map<String, dynamic>>;
          final categoryNames = {
            for (final c in categories)
              c['id'] as String: c['name'] as String? ?? '-',
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Row(
                  children: [
                    AppText(
                      'Categories',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showCategoryDialog(
                        context,
                        ref,
                        widget.gymId,
                        onSaved: _refresh,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    for (final c in categories)
                      _CategoryChip(
                        label: c['name'] as String? ?? '-',
                        selected: _selectedCategoryId == c['id'],
                        onTap: () => setState(
                          () => _selectedCategoryId = c['id'] as String,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            AppText(
                              categories.isEmpty
                                  ? 'Add a category first'
                                  : 'No products in this category',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          final categoryName =
                              categoryNames[p['category_id'] as String?];
                          final stock = (p['stock_qty'] as num?)?.toInt() ?? 0;
                          final isLowStock = stock <= 5;

                          return Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      size: 28,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        p['name'] as String? ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (categoryName != null)
                                        AppText(
                                          categoryName,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(fontSize: 9),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      AppText(
                                        '₹${p['price']}',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: isLowStock
                                              ? Colors.redAccent.withOpacity(
                                                  0.12,
                                                )
                                              : Colors.green.withOpacity(0.12),
                                        ),
                                        child: AppText(
                                          '$stock in stock',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isLowStock
                                                ? Colors.redAccent
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              onPressed: () => _showProductDialog(
                context,
                ref,
                widget.gymId,
                preselectedCategoryId: _selectedCategoryId,
                onSaved: _refresh,
              ),
              heroTag: 'prod',
              elevation: 0,
              backgroundColor: colorScheme.tertiaryContainer,
              child: const Icon(Icons.add_business_rounded, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              onPressed: () => _showCreateSaleDialog(
                context,
                ref,
                widget.gymId,
                categoryId: _selectedCategoryId,
              ),
              heroTag: 'sale',
              elevation: 2,
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: const Text(
                'Sale',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
    );
  }
}

Future<void> _showCategoryDialog(
  BuildContext context,
  WidgetRef ref,
  String gymId, {
  required VoidCallback onSaved,
}) async {
  final navigator = Navigator.of(context);
  final name = TextEditingController();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      icon: const Icon(Icons.category_rounded),
      title: const Text('Add Category'),
      content: AppTextField(
        controller: name,
        label: 'Category name',
        prefixIcon: const Icon(Icons.label_outline, size: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final ok = await runWithErrorDialog(
              context,
              errorTitle: 'Could not save category',
              action: () => ref
                  .read(gymRepositoryProvider)
                  .upsertCategory(gymId: gymId, name: name.text.trim()),
            );
            if (!context.mounted) return;
            if (ok) {
              navigator.pop();
              onSaved();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> _showProductDialog(
  BuildContext context,
  WidgetRef ref,
  String gymId, {
  String? preselectedCategoryId,
  required VoidCallback onSaved,
}) async {
  final navigator = Navigator.of(context);
  final categories = await ref.read(gymRepositoryProvider).categories(gymId);
  if (!context.mounted) return;

  if (categories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create a category before adding products.'),
      ),
    );
    return;
  }

  final name = TextEditingController();
  final price = TextEditingController(text: '0');
  final stock = TextEditingController(text: '0');
  String? categoryId =
      preselectedCategoryId ?? categories.first['id'] as String;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        icon: const Icon(Icons.add_business_rounded),
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined, size: 18),
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String? ?? '-'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setDialogState(() => categoryId = v),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: name,
              label: 'Product name',
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: price,
              label: 'Price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: stock,
              label: 'Stock',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.layers_outlined, size: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (categoryId == null || name.text.trim().isEmpty) return;
              final ok = await runWithErrorDialog(
                dialogContext,
                errorTitle: 'Could not save product',
                action: () => ref
                    .read(gymRepositoryProvider)
                    .upsertProduct(
                      gymId: gymId,
                      categoryId: categoryId!,
                      name: name.text.trim(),
                      price: double.tryParse(price.text) ?? 0,
                      stockQty: int.tryParse(stock.text) ?? 0,
                    ),
              );
              if (!dialogContext.mounted) return;
              if (ok) {
                navigator.pop();
                onSaved();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showCreateSaleDialog(
  BuildContext context,
  WidgetRef ref,
  String gymId, {
  String? categoryId,
}) async {
  final navigator = Navigator.of(context);
  final products = await ref
      .read(gymRepositoryProvider)
      .products(gymId, categoryId: categoryId);
  final members = await ref.read(gymRepositoryProvider).members(gymId);
  if (!context.mounted) return;
  String? productId;
  String? memberId;
  final qty = TextEditingController(text: '1');
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      icon: const Icon(Icons.shopping_cart_checkout_rounded),
      title: const Text('Record Sale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            items: products
                .map(
                  (p) => DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text(p['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (v) => productId = v,
            decoration: const InputDecoration(
              labelText: 'Product',
              prefixIcon: Icon(Icons.inventory, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Walk-in Customer'),
              ),
              ...members.map(
                (m) => DropdownMenuItem(
                  value: m['id'] as String,
                  child: Text(m['full_name'] as String? ?? '-'),
                ),
              ),
            ],
            onChanged: (v) => memberId = v,
            decoration: const InputDecoration(
              labelText: 'Member',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: qty,
            label: 'Quantity',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.numbers, size: 20),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (productId == null) {
              await showAppErrorDialog(
                context,
                title: 'Sale failed',
                error: 'Please select a product.',
              );
              return;
            }
            final ok = await runWithErrorDialog(
              context,
              errorTitle: 'Sale failed',
              action: () => ref
                  .read(gymRepositoryProvider)
                  .createSale(
                    gymId: gymId,
                    memberId: memberId,
                    soldBy: Supabase.instance.client.auth.currentUser!.id,
                    productId: productId!,
                    qty: int.tryParse(qty.text) ?? 1,
                  ),
            );
            if (!context.mounted) return;
            if (ok) navigator.pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
