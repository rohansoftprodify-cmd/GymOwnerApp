import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/core/ui/image_crop_page.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/product_price_display.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({
    super.key,
    required this.gymId,
    required this.categories,
    this.product,
    this.preselectedCategoryId,
  });

  final String gymId;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? product;
  final String? preselectedCategoryId;

  bool get isEdit => product != null;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _actualPriceController = TextEditingController(text: '0');
  final _offerPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  String? _categoryId;
  Uint8List? _imageBytes;
  String? _existingImagePath;
  bool _clearImage = false;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameController.text = p['name'] as String? ?? '';
      _descriptionController.text = p['description'] as String? ?? '';
      _skuController.text = p['sku'] as String? ?? '';
      _actualPriceController.text = _priceText(p['actual_price']) ?? _priceText(p['price']) ?? '0';
      _offerPriceController.text = _priceText(p['offer_price']) ?? '';
      _stockController.text = '${(p['stock_qty'] as num?)?.toInt() ?? 0}';
      _categoryId = p['category_id'] as String?;
      _existingImagePath = p['image_path'] as String?;
      _isActive = p['is_active'] as bool? ?? true;
    } else {
      _categoryId = widget.preselectedCategoryId ??
          (widget.categories.isNotEmpty ? widget.categories.first['id'] as String : null);
    }

    for (final c in [_nameController, _actualPriceController, _offerPriceController, _stockController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _actualPriceController.dispose();
    _offerPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String? _priceText(dynamic value) {
    if (value is! num) return null;
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toStringAsFixed(0);
    return d.toStringAsFixed(2);
  }

  double? get _parsedActual => double.tryParse(_actualPriceController.text.trim());

  double? get _parsedOffer {
    final raw = _offerPriceController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  int? _discountPercent(double actual, double? offer) {
    if (offer == null || offer >= actual || actual <= 0) return null;
    return ((1 - offer / actual) * 100).round();
  }

  Future<void> _pickImage() async {
    final bytes = await pickAndCropImage(
      context,
      cropTitle: 'Crop product photo',
      aspectRatio: 1,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _imageBytes = bytes;
      _clearImage = false;
    });
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _clearImage = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await showAppErrorDialog(context, title: 'Missing name', error: 'Enter a product name.');
      return;
    }
    if (_categoryId == null) {
      await showAppErrorDialog(context, title: 'Missing category', error: 'Select a category.');
      return;
    }

    final actual = _parsedActual;
    if (actual == null || actual < 0) {
      await showAppErrorDialog(context, title: 'Invalid price', error: 'Enter a valid actual price.');
      return;
    }

    final offer = _parsedOffer;
    if (_offerPriceController.text.trim().isNotEmpty && (offer == null || offer < 0)) {
      await showAppErrorDialog(
        context,
        title: 'Invalid offer price',
        error: 'Enter a valid offer price or leave it empty.',
      );
      return;
    }
    if (offer != null && offer > actual) {
      await showAppErrorDialog(
        context,
        title: 'Invalid offer price',
        error: 'Offer price cannot be higher than actual price.',
      );
      return;
    }

    final stock = int.tryParse(_stockController.text.trim());
    if (stock == null || stock < 0) {
      await showAppErrorDialog(context, title: 'Invalid stock', error: 'Enter a valid stock quantity.');
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);
    final description = _descriptionController.text.trim();
    final sku = _skuController.text.trim();

    final ok = await runWithErrorDialog(
      context,
      errorTitle: widget.isEdit ? 'Update failed' : 'Save failed',
      action: () async {
        final row = await repo.upsertProduct(
          gymId: widget.gymId,
          id: widget.product?['id'] as String?,
          categoryId: _categoryId!,
          name: name,
          actualPrice: actual,
          offerPrice: offer,
          stockQty: stock,
          description: description.isEmpty ? null : description,
          sku: sku.isEmpty ? null : sku,
          imagePath: _clearImage ? null : _existingImagePath,
          removeImage: _clearImage,
          isActive: _isActive,
        );
        final productId = row['id'] as String;

        if (_imageBytes != null) {
          final uploadedPath = await repo.uploadProductImage(
            gymId: widget.gymId,
            productId: productId,
            bytes: _imageBytes!,
          );
          await repo.upsertProduct(
            gymId: widget.gymId,
            id: productId,
            categoryId: _categoryId!,
            name: name,
            actualPrice: actual,
            offerPrice: offer,
            stockQty: stock,
            description: description.isEmpty ? null : description,
            sku: sku.isEmpty ? null : sku,
            imagePath: uploadedPath,
            isActive: _isActive,
          );
        }
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final repo = ref.watch(gymRepositoryProvider);
    final actual = _parsedActual ?? 0;
    final offer = _parsedOffer;
    final discount = _discountPercent(actual, offer);
    final imageUrl = !_clearImage && _imageBytes == null
        ? repo.productImageUrl(_existingImagePath)
        : null;
    final categoryName = widget.categories
        .where((c) => c['id'] == _categoryId)
        .map((c) => c['name'] as String? ?? '-')
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit product' : 'Add product'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _HeroCard(isEdit: widget.isEdit),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Product photo',
                  icon: Icons.photo_outlined,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _imagePlaceholder(colorScheme),
                                    )
                                  : _imagePlaceholder(colorScheme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tap to upload & crop photo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_imageBytes != null || imageUrl != null)
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Details',
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Product name',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: widget.categories.any((c) => c['id'] == _categoryId) ? _categoryId : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 18),
                        ),
                        items: widget.categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['name'] as String? ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _skuController,
                        label: 'SKU / code (optional)',
                        prefixIcon: const Icon(Icons.tag_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Pricing',
                  icon: Icons.payments_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _actualPriceController,
                              label: 'Actual price (MRP)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _offerPriceController,
                              label: 'Offer price',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Member sees',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ProductPriceDisplay(
                                    actualPrice: actual,
                                    offerPrice: offer,
                                  ),
                                ],
                              ),
                            ),
                            if (discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: semantics.accentCoral.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$discount% OFF',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: semantics.accentCoral,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Inventory & status',
                  icon: Icons.warehouse_outlined,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _stockController,
                        label: 'Stock quantity',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.layers_outlined, size: 18),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available in shop'),
                        subtitle: Text(
                          _isActive ? 'Visible to members' : 'Hidden from member shop',
                          style: theme.textTheme.labelSmall,
                        ),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                if (_nameController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PreviewCard(
                    name: _nameController.text.trim(),
                    categoryName: categoryName,
                    actualPrice: actual,
                    offerPrice: offer,
                    stock: int.tryParse(_stockController.text.trim()) ?? 0,
                    imageBytes: _imageBytes,
                    imageUrl: imageUrl,
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: semantics.cardBackground,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEdit ? 'Update product' : 'Save product'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          'Add product image',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.secondary, colorScheme.primary],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEdit ? Icons.edit_rounded : Icons.add_shopping_cart_rounded,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Update shop listing' : 'List a new product',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Photo, pricing, and stock — members see this in the shop tab.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.name,
    required this.categoryName,
    required this.actualPrice,
    required this.offerPrice,
    required this.stock,
    this.imageBytes,
    this.imageUrl,
  });

  final String name;
  final String? categoryName;
  final double actualPrice;
  final double? offerPrice;
  final int stock;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop preview',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : imageUrl != null
                          ? Image.network(imageUrl!, fit: BoxFit.cover)
                          : ColoredBox(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (categoryName != null) ...[
                      const SizedBox(height: 2),
                      Text(categoryName!, style: theme.textTheme.labelSmall),
                    ],
                    const SizedBox(height: 6),
                    ProductPriceDisplay(actualPrice: actualPrice, offerPrice: offerPrice),
                  ],
                ),
              ),
              Text(
                '$stock in stock',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: stock <= 5 ? semantics.accentCoral : colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
