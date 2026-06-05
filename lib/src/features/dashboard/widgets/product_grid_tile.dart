import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';

class ProductGridTile extends StatelessWidget {
  const ProductGridTile({
    super.key,
    required this.name,
    required this.price,
    required this.stockQty,
    this.categoryName,
    this.imageUrl,
  });

  final String name;
  final double price;
  final int stockQty;
  final String? categoryName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowStock = stockQty <= 5;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => ProductImagePlaceholder(
                      colorScheme: colorScheme,
                    ),
                  )
                : ProductImagePlaceholder(colorScheme: colorScheme),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (categoryName != null) ...[
                    const SizedBox(height: 2),
                    AppText(
                      categoryName!,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      AppText(
                        '₹${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: isLowStock
                              ? Colors.redAccent.withValues(alpha: 0.12)
                              : Colors.green.withValues(alpha: 0.12),
                        ),
                        child: AppText(
                          '$stockQty',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isLowStock ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: 28,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
