import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/product_grid_tile.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/products_category_section.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/products_dialogs.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/products_empty_state.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/products_fab_actions.dart';

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  String? _selectedCategoryId;
  int _reloadToken = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  void _refresh() => setState(() => _reloadToken++);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final repo = ref.watch(gymRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_reloadToken),
        future: Future.wait<dynamic>([
          repo.categories(widget.gymId),
          repo.products(
            widget.gymId,
            categoryId: _searchQuery.isNotEmpty ? null : _selectedCategoryId,
          ),
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

          final filteredProducts = products.where((p) {
            if (_searchQuery.isEmpty) return true;
            final name = (p['name'] as String? ?? '').toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                    hintText: 'Search products by name...',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ProductsCategorySection(
                categories: categories,
                selectedCategoryId: _searchQuery.isNotEmpty ? null : _selectedCategoryId,
                onCategorySelected: (id) {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoryId = id;
                  });
                },
                onAddCategory: () => showAddCategoryDialog(
                  context,
                  ref,
                  widget.gymId,
                  onSaved: _refresh,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredProducts.isEmpty
                    ? ProductsEmptyState(hasCategories: categories.isNotEmpty)
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (_, i) {
                          final p = filteredProducts[i];
                          final categoryName =
                              categoryNames[p['category_id'] as String?];
                          final stock = (p['stock_qty'] as num?)?.toInt() ?? 0;
                          final actualPrice =
                              (p['actual_price'] as num?)?.toDouble() ??
                              (p['price'] as num?)?.toDouble() ??
                              0;
                          final offerPrice = (p['offer_price'] as num?)?.toDouble();
                          final imageUrl = repo.productImageUrl(
                            p['image_path'] as String?,
                          );

                          return ProductGridTile(
                            name: p['name'] as String? ?? '-',
                            categoryName: categoryName,
                            actualPrice: actualPrice,
                            offerPrice: offerPrice,
                            stockQty: stock,
                            imageUrl: imageUrl,
                            onTap: () => showEditProductDialog(
                              context,
                              ref,
                              widget.gymId,
                              product: p,
                              onSaved: _refresh,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ProductsFabActions(
        onAddProduct: () => showAddProductDialog(
          context,
          ref,
          widget.gymId,
          preselectedCategoryId: _selectedCategoryId,
          onSaved: _refresh,
        ),
        onRecordSale: () => showCreateSaleDialog(
          context,
          ref,
          widget.gymId,
          categoryId: _selectedCategoryId,
        ),
      ),
    );
  }
}
