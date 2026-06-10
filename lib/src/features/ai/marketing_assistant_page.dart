import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/ai/marketing_template_generator.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/diet_ai_quota.dart';
import 'package:gym_owner_app/src/features/ai/models/marketing_content_result.dart';

class MarketingAssistantPage extends ConsumerStatefulWidget {
  const MarketingAssistantPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<MarketingAssistantPage> createState() => _MarketingAssistantPageState();
}

class _MarketingAssistantPageState extends ConsumerState<MarketingAssistantPage> {
  final _promptController = TextEditingController();
  final _offerController = TextEditingController();
  final _memberNameController = TextEditingController();

  MarketingContentType _contentType = MarketingContentType.festivalOffer;
  MarketingContentResult? _result;
  DietAiQuota? _quota;
  bool _loadingQuota = true;
  bool _generating = false;

  static const _quickPrompts = [
    'Create a Diwali membership promotion',
    'New Year transformation offer',
    'Summer shred challenge post',
    'Member transformation reel caption',
    'Push notification for overdue fee reminder',
  ];

  @override
  void initState() {
    super.initState();
    _promptController.text = _quickPrompts.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuota());
  }

  @override
  void dispose() {
    _promptController.dispose();
    _offerController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await ref.read(aiRepositoryProvider).getMarketingAiQuota(widget.gymId);
      if (mounted) setState(() {
        _quota = quota;
        _loadingQuota = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _quota = const DietAiQuota(used: 0, limit: 10, remaining: 10);
        _loadingQuota = false;
      });
    }
  }

  Future<String> _gymName() async {
    final tenant = await ref.read(tenantContextProvider.future);
    return tenant?.gymName ?? 'Your Gym';
  }

  Future<void> _generate({required bool useAi}) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      await showAppErrorDialog(context, title: 'Missing prompt', error: 'Describe what to create.');
      return;
    }

    setState(() => _generating = true);
    try {
      final gymName = await _gymName();
      final offerHint = _offerController.text.trim();
      final memberName = _memberNameController.text.trim();

      final Map<String, dynamic> raw;
      if (useAi) {
        raw = await ref.read(aiRepositoryProvider).generateMarketingContent(
              gymId: widget.gymId,
              contentType: _contentType.key,
              prompt: prompt,
              mode: MarketingGenerateMode.ai,
              offerHint: offerHint.isEmpty ? null : offerHint,
              memberName: memberName.isEmpty ? null : memberName,
            );
        await _loadQuota();
      } else {
        raw = await MarketingTemplateGenerator.generate(
          contentType: _contentType,
          gymName: gymName,
          prompt: prompt,
          offerHint: offerHint.isEmpty ? null : offerHint,
          memberName: memberName.isEmpty ? null : memberName,
        );
      }

      if (!mounted) return;
      setState(() {
        _result = MarketingContentResult.fromMap(raw);
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      await showAppErrorDialog(context, title: 'Generation failed', error: e);
    }
  }

  void _copy(String label, String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final result = _result;
    final quota = _quota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Marketing Assistant'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Generate Instagram posts, transformation captions, festival offers, and push notifications. Template mode is free; AI enhance uses monthly quota.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Content type',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MarketingContentType.values.map((type) {
              return ChoiceChip(
                label: Text(type.label, style: const TextStyle(fontSize: 12)),
                selected: _contentType == type,
                onSelected: (_) => setState(() => _contentType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Your prompt',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What should we create?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickPrompts.map((p) {
              return ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _promptController.text = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _offerController,
            label: 'Offer details (optional, e.g. 20% off annual plan)',
          ),
          if (_contentType == MarketingContentType.transformationCaption) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _memberNameController,
              label: 'Member name (optional)',
            ),
          ],
          const SizedBox(height: 16),
          if (!_loadingQuota && quota != null)
            Text(
              'AI quota: ${quota.remaining}/${quota.limit} left this month',
              style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _generating ? null : () => _generate(useAi: false),
                  icon: const Icon(Icons.article_outlined, size: 18),
                  label: const Text('Use template'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generating || (quota?.remaining ?? 0) <= 0
                      ? null
                      : () => _generate(useAi: true),
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('AI enhance'),
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Text(
              'Generated content',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.festivalLabel} · ${result.mode == 'ai' ? 'AI' : 'Template'}',
              style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
            ),
            const SizedBox(height: 10),
            _CopyCard(
              title: result.title,
              body: result.body,
              onCopy: () => _copy('Content', result.body),
            ),
            if (result.instagramCaption.isNotEmpty &&
                result.contentType != MarketingContentType.pushNotification.key) ...[
              const SizedBox(height: 10),
              _CopyCard(
                title: 'Instagram caption',
                body: result.instagramCaption,
                onCopy: () => _copy('Instagram caption', result.instagramCaption),
              ),
            ],
            if (result.contentType == MarketingContentType.pushNotification.key ||
                result.pushNotification.title.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CopyCard(
                title: 'Push: ${result.pushNotification.title}',
                body: result.pushNotification.body,
                onCopy: () => _copy(
                  'Push notification',
                  '${result.pushNotification.title}\n${result.pushNotification.body}',
                ),
              ),
            ],
            if (result.hashtags.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CopyCard(
                title: 'Hashtags',
                body: result.hashtags.join(' '),
                onCopy: () => _copy('Hashtags', result.hashtags.join(' ')),
              ),
            ],
            if (result.cta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('CTA: ${result.cta}', style: theme.textTheme.labelMedium),
            ],
          ],
        ],
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({
    required this.title,
    required this.body,
    required this.onCopy,
  });

  final String title;
  final String body;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy',
                ),
              ],
            ),
            Text(body, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
