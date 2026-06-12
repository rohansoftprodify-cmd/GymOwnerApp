import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/product_price_display.dart';

class ProductGridTile extends StatelessWidget {
  const ProductGridTile({
    super.key,
    required this.name,
    required this.actualPrice,
    this.offerPrice,
    required this.stockQty,
    this.categoryName,
    this.imageUrl,
    this.onTap,
  });

  final String name;
  final double actualPrice;
  final double? offerPrice;
  final int stockQty;
  final String? categoryName;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowStock = stockQty <= 5;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => ProductImagePlaceholder(
                            colorScheme: colorScheme,
                          ),
                        )
                      : ProductImagePlaceholder(colorScheme: colorScheme),
                  if (onTap != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
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
                        Expanded(
                          child: ProductPriceDisplay(
                            actualPrice: actualPrice,
                            offerPrice: offerPrice,
                            compact: true,
                          ),
                        ),
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
