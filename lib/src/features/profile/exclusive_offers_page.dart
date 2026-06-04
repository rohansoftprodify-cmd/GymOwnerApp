import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/exclusive_offer_card.dart';
import 'package:gym_owner_app/src/features/profile/models/promotion_item.dart';
import 'package:gym_owner_app/src/features/profile/widgets/promotion_form_dialog.dart';

class ExclusiveOffersPage extends ConsumerStatefulWidget {
  const ExclusiveOffersPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<ExclusiveOffersPage> createState() => _ExclusiveOffersPageState();
}

class _ExclusiveOffersPageState extends ConsumerState<ExclusiveOffersPage> {
  bool _loading = true;
  List<PromotionItem> _offers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await ref.read(gymRepositoryProvider).promotions(widget.gymId);
      if (!mounted) return;
      setState(() {
        _offers = rows.map(PromotionItem.fromMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _openForm({PromotionItem? existing}) async {
    await showPromotionFormDialog(
      context,
      ref,
      gymId: widget.gymId,
      existing: existing,
      onSaved: _load,
    );
  }

  Future<void> _toggleActive(PromotionItem offer) async {
    if (offer.id == null) return;

    if (offer.isActive) {
      final confirm = await showConfirmDialog(
        context,
        title: 'Deactivate offer?',
        message: '“${offer.title}” will be removed from the home carousel.',
        confirmLabel: 'Deactivate',
        icon: Icons.visibility_off_outlined,
      );
      if (!confirm || !mounted) return;
    }

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Update failed',
      action: () => ref.read(gymRepositoryProvider).setPromotionActive(
            gymId: widget.gymId,
            promotionId: offer.id!,
            isActive: !offer.isActive,
          ),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_offers.isEmpty)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: semantics.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No exclusive offers',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create promotions to show on the home screen carousel.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add first offer'),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: _offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final offer = _offers[i];
              return _OfferManageTile(
                offer: offer,
                onEdit: () => _openForm(existing: offer),
                onToggleActive: () => _toggleActive(offer),
              );
            },
          ),
        if (_offers.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add offer'),
            ),
          ),
      ],
    );
  }
}

class _OfferManageTile extends StatelessWidget {
  const _OfferManageTile({
    required this.offer,
    required this.onEdit,
    required this.onToggleActive,
  });

  final PromotionItem offer;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final status = offer.displayStatus();

    Color badgeColor;
    switch (status) {
      case PromotionDisplayStatus.active:
        badgeColor = theme.colorScheme.primary;
      case PromotionDisplayStatus.upcoming:
        badgeColor = semantics.accentLime;
      case PromotionDisplayStatus.expired:
      case PromotionDisplayStatus.inactive:
        badgeColor = semantics.accentCoral;
    }

    final badgeTextColor = status == PromotionDisplayStatus.upcoming
        ? semantics.onAccentLime
        : (status == PromotionDisplayStatus.active
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onError);

    return Opacity(
      opacity: offer.isActive ? 1 : 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ExclusiveOfferCard(offer: offer.toOfferMap()),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              TextButton.icon(
                onPressed: onToggleActive,
                icon: Icon(
                  offer.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(
                  offer.isActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor:
                      offer.isActive ? semantics.accentCoral : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
