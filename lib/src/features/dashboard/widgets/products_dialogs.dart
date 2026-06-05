import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showAddCategoryDialog(
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
              Navigator.of(context).pop();
              runAfterDialogClosed(onSaved);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showAddProductDialog(
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
              initialValue: categoryId,
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
                Navigator.of(dialogContext).pop();
                runAfterDialogClosed(onSaved);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCreateSaleDialog(
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
