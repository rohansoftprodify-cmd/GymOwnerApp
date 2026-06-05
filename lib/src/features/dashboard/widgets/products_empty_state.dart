import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';

class ProductsEmptyState extends StatelessWidget {
  const ProductsEmptyState({
    super.key,
    required this.hasCategories,
  });

  final bool hasCategories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
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
            hasCategories ? 'No products in this category' : 'Add a category first',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
