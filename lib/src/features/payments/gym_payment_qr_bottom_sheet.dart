import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/payments/gym_payment_options_provider.dart';

Future<void> showGymPaymentQrBottomSheet(
  BuildContext context, {
  required String gymId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => GymPaymentQrBottomSheet(gymId: gymId),
  );
}

class GymPaymentQrBottomSheet extends ConsumerStatefulWidget {
  const GymPaymentQrBottomSheet({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymPaymentQrBottomSheet> createState() => _GymPaymentQrBottomSheetState();
}

class _GymPaymentQrBottomSheetState extends ConsumerState<GymPaymentQrBottomSheet> {
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _settingPrimary = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setPrimary(String optionId) async {
    if (_settingPrimary) return;
    setState(() => _settingPrimary = true);
    try {
      await ref.read(gymRepositoryProvider).setPrimaryGymPaymentOption(
            gymId: widget.gymId,
            optionId: optionId,
          );
      ref.invalidate(gymPaymentOptionsProvider(widget.gymId));
      if (mounted) {
        setState(() => _pageIndex = 0);
        if (_pageController.hasClients) {
          await _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not set primary: $error')),
      );
    } finally {
      if (mounted) setState(() => _settingPrimary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final optionsAsync = ref.watch(gymPaymentOptionsProvider(widget.gymId));
    final repo = ref.watch(gymRepositoryProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: optionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (options) {
            if (options.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'No payment QR yet',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a UPI ID and QR code in gym profile so members can pay you.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/gym-payment-options?gymId=${widget.gymId}');
                      },
                      child: const Text('Set up payment QR'),
                    ),
                  ],
                ),
              );
            }

            if (_pageIndex >= options.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _pageIndex = 0);
              });
            }

            final current = options[_pageIndex.clamp(0, options.length - 1)];
            final currentId = current['id'] as String;
            final isPrimary = current['is_primary'] == true;
            final multiple = options.length > 1;
            final upiId = current['upi_id'] as String?;
            final label = _labelFor(current, _pageIndex);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment QR',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: semantics.accentLime.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Primary',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: semantics.onAccentLime,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: options.length,
                    onPageChanged: (index) => setState(() => _pageIndex = index),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final imageUrl =
                          repo.paymentQrImageUrl(option['qr_image_path'] as String?);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl != null
                              ? Image.network(imageUrl, fit: BoxFit.contain)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 56,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No QR image',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (multiple) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < options.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _pageIndex == i ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _pageIndex == i
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe for more QR codes',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_hasText(upiId))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UPI ID',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  upiId!,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy UPI ID',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: upiId));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('UPI ID copied'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'No UPI ID on this option',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (multiple && !isPrimary) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      onPressed: _settingPrimary ? null : () => _setPrimary(currentId),
                      icon: _settingPrimary
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Set as primary QR'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _labelFor(Map<String, dynamic> option, int index) {
    final label = option['label'];
    if (label is String && label.trim().isNotEmpty) return label.trim();
    return 'Payment ${index + 1}';
  }

  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
