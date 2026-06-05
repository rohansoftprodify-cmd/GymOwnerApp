import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/product_category_chip.dart';

class ProductsCategorySection extends StatelessWidget {
  const ProductsCategorySection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                onPressed: onAddCategory,
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
              ProductCategoryChip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              ),
              for (final c in categories)
                ProductCategoryChip(
                  label: c['name'] as String? ?? '-',
                  selected: selectedCategoryId == c['id'],
                  onTap: () => onCategorySelected(c['id'] as String),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
