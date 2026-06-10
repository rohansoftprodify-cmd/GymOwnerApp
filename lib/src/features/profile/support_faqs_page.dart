import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/support_faq_item.dart';
import 'package:gym_owner_app/src/features/profile/widgets/support_faq_form_dialog.dart';

class SupportFaqsPage extends ConsumerStatefulWidget {
  const SupportFaqsPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<SupportFaqsPage> createState() => _SupportFaqsPageState();
}

class _SupportFaqsPageState extends ConsumerState<SupportFaqsPage> {
  bool _loading = true;
  List<SupportFaqItem> _faqs = [];
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      await repo.ensureDefaultSupportFaqs(widget.gymId);
      final rows = await repo.supportFaqs(widget.gymId, category: _filterCategory);
      if (!mounted) return;
      setState(() {
        _faqs = rows.map(SupportFaqItem.fromMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _applyFilter(String? category) async {
    if (_filterCategory == category) return;
    _filterCategory = category;
    await _load();
  }

  Future<void> _openForm({SupportFaqItem? existing}) async {
    final result = await showSupportFaqFormDialog(context, existing: existing);
    if (result == null || !mounted) return;

    try {
      await ref.read(gymRepositoryProvider).upsertSupportFaq(
            gymId: widget.gymId,
            id: existing?.id,
            category: result.category,
            question: result.question,
            answer: result.answer,
            sortOrder: result.sortOrder,
            isActive: result.isActive,
          );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Save failed', error: error);
    }
  }

  Future<void> _toggleActive(SupportFaqItem faq) async {
    try {
      await ref.read(gymRepositoryProvider).setSupportFaqActive(
            gymId: widget.gymId,
            faqId: faq.id,
            isActive: !faq.isActive,
          );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Update failed', error: error);
    }
  }

  Future<void> _delete(SupportFaqItem faq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete question?'),
        content: Text('Remove “${faq.question}” from the support bot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(gymRepositoryProvider).deleteSupportFaq(
            gymId: widget.gymId,
            faqId: faq.id,
          );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Delete failed', error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Support Bot'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Q&A'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Members pick a question in the app and see your answer instantly — fewer calls at the desk.',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: semantics.mutedText,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _filterCategory == null,
                        onTap: () => _applyFilter(null),
                      ),
                      for (final key in SupportFaqCategory.all) ...[
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: SupportFaqCategory.label(key),
                          selected: _filterCategory == key,
                          onTap: () => _applyFilter(key),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _faqs.isEmpty
                      ? Center(
                          child: Text(
                            'No questions yet. Tap Add Q&A to create one.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: semantics.mutedText,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: _faqs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final faq = _faqs[index];
                            return _FaqCard(
                              faq: faq,
                              onEdit: () => _openForm(existing: faq),
                              onToggle: () => _toggleActive(faq),
                              onDelete: () => _delete(faq),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      checkmarkColor: colorScheme.primary,
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.faq,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SupportFaqItem faq;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Material(
      color: semantics.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    SupportFaqCategory.label(faq.category),
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (!faq.isActive)
                  Text(
                    'Hidden',
                    style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              faq.question,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              faq.answer,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: semantics.mutedText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Order ${faq.sortOrder}',
                  style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                ),
                const Spacer(),
                IconButton(
                  tooltip: faq.isActive ? 'Hide from members' : 'Show to members',
                  onPressed: onToggle,
                  icon: Icon(
                    faq.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: colorScheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
