import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';

class ProductPriceDisplay extends StatelessWidget {
  const ProductPriceDisplay({
    super.key,
    required this.actualPrice,
    this.offerPrice,
    this.priceStyle,
    this.strikeStyle,
    this.compact = false,
  });

  final double actualPrice;
  final double? offerPrice;
  final TextStyle? priceStyle;
  final TextStyle? strikeStyle;
  final bool compact;

  bool get _hasOffer =>
      offerPrice != null && offerPrice! > 0 && offerPrice! < actualPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selling = _hasOffer ? offerPrice! : actualPrice;
    final mainStyle = priceStyle ??
        TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 13 : 14,
        );
    final mutedStyle = strikeStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          decoration: TextDecoration.lineThrough,
          fontSize: compact ? 9 : 10,
        );

    if (!_hasOffer) {
      return AppText('₹${selling.toStringAsFixed(0)}', style: mainStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText('₹${selling.toStringAsFixed(0)}', style: mainStyle),
        const SizedBox(width: 4),
        Flexible(
          child: AppText(
            '₹${actualPrice.toStringAsFixed(0)}',
            style: mutedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
