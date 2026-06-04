import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';

class AddMemberPage extends ConsumerStatefulWidget {
  const AddMemberPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends ConsumerState<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController(text: '0');

  List<Map<String, dynamic>> _plans = [];
  String? _planId;
  DateTime _startDate = DateTime.now();
  String _paymentStatus = 'due';
  bool _loadingPlans = true;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emergencyController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await ref.read(gymRepositoryProvider).plans(widget.gymId);
      if (!mounted) return;
      setState(() {
        _plans = plans.where((p) => p['is_active'] == true).toList();
        if (_plans.isNotEmpty) _planId = _plans.first['id'] as String?;
        _loadingPlans = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingPlans = false);
      await showAppErrorDialog(context, title: 'Load plans failed', error: error);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _planId == null) return;

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Create member failed',
      action: () async {
        final result = await repo.createMemberAccount(
          gymId: widget.gymId,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          planId: _planId!,
          startDate: _startDate,
          paymentStatus: _paymentStatus,
          amountPaid: double.tryParse(_amountPaidController.text.trim()) ?? 0,
          emergencyContact: _emergencyController.text.trim().isEmpty
              ? null
              : _emergencyController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (!mounted) return;
        final credentials = result['credentials'] as Map<String, dynamic>? ?? const {};
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Member created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share these login details with the member for the Gym Member app:'),
                const SizedBox(height: 12),
                SelectableText('Email: ${credentials['email'] ?? _emailController.text.trim()}'),
                SelectableText('Password: ${credentials['password'] ?? _passwordController.text}'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPlans) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add member')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_plans.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add member')),
        body: const Center(child: Text('Create an active membership plan first.')),
      );
    }

    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Add member')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Creates a gym member linked to this gym only, with app login credentials.',
            style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Full name',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _emailController,
                  label: 'Email (login)',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _passwordController,
                  label: 'Temporary password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _emergencyController,
                  label: 'Emergency contact (optional)',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes (optional)',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Membership',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _plans.any((p) => p['id'] == _planId) ? _planId : _plans.first['id'] as String,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: _plans
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text('${p['name']} · ₹${p['price']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _planId = v),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(_startDate.toIso8601String().substring(0, 10)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentStatus,
                  decoration: const InputDecoration(labelText: 'Payment status'),
                  items: const [
                    DropdownMenuItem(value: 'due', child: Text('Due')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _paymentStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _amountPaidController,
                  label: 'Amount paid',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create member account'),
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
