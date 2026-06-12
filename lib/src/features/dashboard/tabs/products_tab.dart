import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
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

  void _refresh() => setState(() => _reloadToken++);

  @override
  Widget build(BuildContext context) {
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
              ProductsCategorySection(
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                onAddCategory: () => showAddCategoryDialog(
                  context,
                  ref,
                  widget.gymId,
                  onSaved: _refresh,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: products.isEmpty
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
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
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
