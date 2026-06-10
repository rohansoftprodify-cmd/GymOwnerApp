import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/features/profile/models/support_faq_item.dart';

class SupportFaqFormResult {
  const SupportFaqFormResult({
    required this.category,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
  });

  final String category;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
}

Future<SupportFaqFormResult?> showSupportFaqFormDialog(
  BuildContext context, {
  SupportFaqItem? existing,
}) {
  return showDialog<SupportFaqFormResult>(
    context: context,
    builder: (ctx) => _SupportFaqFormDialog(existing: existing),
  );
}

class _SupportFaqFormDialog extends StatefulWidget {
  const _SupportFaqFormDialog({this.existing});

  final SupportFaqItem? existing;

  @override
  State<_SupportFaqFormDialog> createState() => _SupportFaqFormDialogState();
}

class _SupportFaqFormDialogState extends State<_SupportFaqFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _sortController;
  late String _category;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _questionController = TextEditingController(text: existing?.question ?? '');
    _answerController = TextEditingController(text: existing?.answer ?? '');
    _sortController = TextEditingController(
      text: (existing?.sortOrder ?? 0).toString(),
    );
    _category = existing?.category ?? SupportFaqCategory.gymTimings;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final sortOrder = int.tryParse(_sortController.text.trim()) ?? 0;
    Navigator.of(context).pop(
      SupportFaqFormResult(
        category: _category,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        sortOrder: sortOrder,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit support answer' : 'Add support answer'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final key in SupportFaqCategory.all)
                      DropdownMenuItem(
                        value: key,
                        child: Text(SupportFaqCategory.label(key)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _questionController,
                  label: 'Question (shown to members)',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Question is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _answerController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Answer is required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _sortController,
                  label: 'Sort order',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Visible to members',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
