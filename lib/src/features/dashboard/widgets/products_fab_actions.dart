import 'package:flutter/material.dart';

class ProductsFabActions extends StatelessWidget {
  const ProductsFabActions({
    super.key,
    required this.onAddProduct,
    required this.onRecordSale,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onRecordSale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: onAddProduct,
            heroTag: 'prod',
            elevation: 0,
            backgroundColor: colorScheme.tertiaryContainer,
            child: Icon(
              Icons.add_business_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: onRecordSale,
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
    );
  }
}
