import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/gym_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/core/ui/image_crop_page.dart';
import 'package:gym_owner_app/src/features/payments/gym_payment_options_provider.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';

const _minSlots = 1;
const _maxSlots = 5;

class GymPaymentOptionsPage extends ConsumerStatefulWidget {
  const GymPaymentOptionsPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymPaymentOptionsPage> createState() => _GymPaymentOptionsPageState();
}

class _PaymentSlot {
  _PaymentSlot({this.id, this.isPrimary = false});

  String? id;
  bool isPrimary;
  final labelController = TextEditingController();
  final upiController = TextEditingController();
  String? existingImagePath;
  Uint8List? newImageBytes;
  bool clearImage = false;

  void dispose() {
    labelController.dispose();
    upiController.dispose();
  }

  bool get hasContent =>
      upiController.text.trim().isNotEmpty ||
      newImageBytes != null ||
      (!clearImage && existingImagePath != null && existingImagePath!.isNotEmpty);

  String? get effectiveImagePath => clearImage ? null : existingImagePath;
}

class _GymPaymentOptionsPageState extends ConsumerState<GymPaymentOptionsPage> {
  bool _loading = true;
  bool _saving = false;
  int? _settingPrimaryIndex;
  final _slots = <_PaymentSlot>[];
  final _removedIds = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  void _ensureMinSlots() {
    while (_slots.length < _minSlots) {
      _slots.add(_PaymentSlot());
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final rows = await repo.gymPaymentOptions(widget.gymId);
      if (!mounted) return;

      for (final slot in _slots) {
        slot.dispose();
      }
      _slots.clear();
      _removedIds.clear();

      for (final row in rows) {
        final slot = _PaymentSlot(
          id: row['id'] as String?,
          isPrimary: row['is_primary'] == true,
        );
        slot.labelController.text = row['label'] as String? ?? '';
        slot.upiController.text = row['upi_id'] as String? ?? '';
        slot.existingImagePath = row['qr_image_path'] as String?;
        _slots.add(slot);
      }
      _ensureMinSlots();
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  void _addSlot() {
    if (_slots.length >= _maxSlots) return;
    setState(() => _slots.add(_PaymentSlot()));
  }

  void _removeSlot(int index) {
    if (_slots.length <= _minSlots) return;
    final slot = _slots[index];
    if (slot.id != null) {
      _removedIds.add(slot.id!);
    }
    setState(() {
      slot.dispose();
      _slots.removeAt(index);
    });
  }

  Future<void> _pickQr(int index) async {
    final bytes = await pickAndCropImage(
      context,
      cropTitle: 'Crop QR code',
      aspectRatio: 1,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _slots[index].newImageBytes = bytes;
      _slots[index].clearImage = false;
    });
  }

  void _clearQr(int index) {
    setState(() {
      _slots[index].newImageBytes = null;
      _slots[index].clearImage = true;
    });
  }

  int get _filledSlotCount => _slots.where((s) => s.hasContent).length;

  void _markPrimaryLocally(int index) {
    for (var i = 0; i < _slots.length; i++) {
      _slots[i].isPrimary = i == index;
    }
  }

  Future<void> _setPrimary(int index) async {
    final slot = _slots[index];
    if (!slot.hasContent || slot.isPrimary) return;

    if (slot.id == null) {
      setState(() => _markPrimaryLocally(index));
      return;
    }

    setState(() => _settingPrimaryIndex = index);
    try {
      await ref.read(gymRepositoryProvider).setPrimaryGymPaymentOption(
            gymId: widget.gymId,
            optionId: slot.id!,
          );
      ref.invalidate(gymPaymentOptionsProvider(widget.gymId));
      if (!mounted) return;
      setState(() => _markPrimaryLocally(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary QR updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Update failed', error: error);
    } finally {
      if (mounted) setState(() => _settingPrimaryIndex = null);
    }
  }

  bool _isValidUpi(String value) {
    if (value.isEmpty) return true;
    return RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(value);
  }

  Future<void> _save() async {
    if (_saving) return;

    for (var i = 0; i < _slots.length; i++) {
      final upi = _slots[i].upiController.text.trim();
      if (!_isValidUpi(upi)) {
        await showAppErrorDialog(
          context,
          title: 'Invalid UPI ID',
          error: 'Payment ${i + 1}: use format name@bank (e.g. gym@paytm).',
        );
        return;
      }
      if (_slots[i].hasContent && upi.isEmpty && _slots[i].newImageBytes == null && _slots[i].effectiveImagePath == null) {
        await showAppErrorDialog(
          context,
          title: 'Missing payment details',
          error: 'Payment ${i + 1}: add a UPI ID or QR code image.',
        );
        return;
      }
    }

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    try {
      for (final id in _removedIds) {
        await repo.deleteGymPaymentOption(gymId: widget.gymId, id: id);
      }

      var sortOrder = 0;
      for (final slot in _slots) {
        if (!slot.hasContent) {
          if (slot.id != null) {
            await repo.deleteGymPaymentOption(gymId: widget.gymId, id: slot.id!);
          }
          continue;
        }

        var row = await repo.upsertGymPaymentOption(
          gymId: widget.gymId,
          id: slot.id,
          label: slot.labelController.text,
          upiId: slot.upiController.text,
          qrImagePath: slot.effectiveImagePath,
          sortOrder: sortOrder,
        );
        sortOrder++;

        final optionId = row['id'] as String;
        slot.id = optionId;
        if (slot.newImageBytes != null) {
          final path = await repo.uploadPaymentQrImage(
            gymId: widget.gymId,
            paymentOptionId: optionId,
            bytes: slot.newImageBytes!,
          );
          row = await repo.upsertGymPaymentOption(
            gymId: widget.gymId,
            id: optionId,
            label: slot.labelController.text,
            upiId: slot.upiController.text,
            qrImagePath: path,
            sortOrder: row['sort_order'] as int? ?? sortOrder - 1,
          );
        }
      }

      if (_filledSlotCount > 1) {
        final primaryIndex = _slots.indexWhere((s) => s.isPrimary && s.hasContent);
        if (primaryIndex >= 0 && _slots[primaryIndex].id != null) {
          await repo.setPrimaryGymPaymentOption(
            gymId: widget.gymId,
            optionId: _slots[primaryIndex].id!,
          );
        }
      }

      ref.invalidate(gymPaymentOptionsProvider(widget.gymId));
      ref.invalidate(gymProfileProvider(widget.gymId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment options saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Save failed', error: error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final filledCount = _filledSlotCount;
    final showPrimaryActions = filledCount > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment QR & UPI'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _HeroCard(filledCount: filledCount),
                      const SizedBox(height: 16),
                      for (var i = 0; i < _slots.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _SlotCard(
                          index: i,
                          slot: _slots[i],
                          repo: ref.read(gymRepositoryProvider),
                          canRemove: _slots.length > _minSlots,
                          showPrimaryAction: showPrimaryActions && _slots[i].hasContent,
                          settingPrimary: _settingPrimaryIndex == i,
                          onPickQr: () => _pickQr(i),
                          onClearQr: () => _clearQr(i),
                          onRemove: () => _removeSlot(i),
                          onSetPrimary: () => _setPrimary(i),
                        ),
                      ],
                      if (_slots.length < _maxSlots) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _addSlot,
                          icon: const Icon(Icons.add_rounded),
                          label: Text('Add payment method (${_slots.length}/$_maxSlots)'),
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
                          : const Text('Save payment options'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.filledCount});

  final int filledCount;

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
          colors: [colorScheme.tertiary, colorScheme.primary],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_outlined, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share how members can pay',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a UPI ID and QR code. With multiple options, pick one as primary. Members see these on your gym profile.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$filledCount of $_maxSlots configured',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
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

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.index,
    required this.slot,
    required this.repo,
    required this.canRemove,
    required this.showPrimaryAction,
    required this.settingPrimary,
    required this.onPickQr,
    required this.onClearQr,
    required this.onRemove,
    required this.onSetPrimary,
  });

  final int index;
  final _PaymentSlot slot;
  final GymRepository repo;
  final bool canRemove;
  final bool showPrimaryAction;
  final bool settingPrimary;
  final VoidCallback onPickQr;
  final VoidCallback onClearQr;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final imageUrl = slot.newImageBytes == null && !slot.clearImage
        ? repo.paymentQrImageUrl(slot.existingImagePath)
        : null;

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
              Text(
                'Payment ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (slot.isPrimary) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: semantics.accentLime.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Primary',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: semantics.onAccentLime,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (canRemove)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: slot.labelController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g. Main counter, Google Pay',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: slot.upiController,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'yourgym@paytm',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
              isDense: true,
            ),
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Text(
            'QR code image',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickQr,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: slot.newImageBytes != null
                  ? Image.memory(slot.newImageBytes!, fit: BoxFit.contain)
                  : imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 40, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload & crop QR code',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          if (slot.newImageBytes != null || imageUrl != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearQr,
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Remove image'),
              ),
            ),
          ],
          if (showPrimaryAction) ...[
            const SizedBox(height: 10),
            if (slot.isPrimary)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: semantics.accentLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: semantics.accentLime.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 18, color: semantics.onAccentLime),
                    const SizedBox(width: 8),
                    Text(
                      'Primary QR for members',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: semantics.onAccentLime,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: settingPrimary ? null : onSetPrimary,
                  icon: settingPrimary
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star_outline_rounded, size: 18),
                  label: Text(
                    slot.id == null ? 'Set as primary (save to apply)' : 'Set as primary QR',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
