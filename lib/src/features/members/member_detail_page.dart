import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/members/models/member_detail.dart';
import 'package:intl/intl.dart';

class MemberDetailPage extends ConsumerStatefulWidget {
  const MemberDetailPage({
    super.key,
    required this.gymId,
    required this.memberId,
  });

  final String gymId;
  final String memberId;

  @override
  ConsumerState<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends ConsumerState<MemberDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginPasswordConfirmController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _updatingLogin = false;
  bool _obscureLoginPassword = true;
  bool _obscureLoginPasswordConfirm = true;
  MemberDetail? _detail;
  List<Map<String, dynamic>> _plans = [];
  String? _planId;
  DateTime _startDate = DateTime.now();
  String _memberStatus = 'active';
  String _paymentStatus = 'due';
  String? _subscriptionId;
  String _subscriptionStatus = 'active';
  int? _computedEndDays;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    _loginPasswordController.dispose();
    _loginPasswordConfirmController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final row = await repo.memberDetail(widget.gymId, widget.memberId);
      final plans = await repo.plans(widget.gymId);
      if (!mounted) return;

      final detail = MemberDetail.fromMap(row);
      final activePlans = plans.where((p) => p['is_active'] == true).toList();
      final sub = detail.activeSubscription;

      _nameController.text = detail.fullName;
      _phoneController.text = detail.phone;
      _emailController.text = detail.email ?? '';
      _emergencyController.text = detail.emergencyContact ?? '';
      _notesController.text = detail.notes ?? '';
      _memberStatus = detail.status;

      if (sub != null) {
        _subscriptionId = sub.id;
        _planId = sub.planId;
        _startDate = sub.startDate;
        _paymentStatus = sub.paymentStatus;
        _amountPaidController.text = sub.amountPaid.toStringAsFixed(
          sub.amountPaid.truncateToDouble() == sub.amountPaid ? 0 : 2,
        );
        _subscriptionStatus = sub.status;
        _computedEndDays = sub.durationDays;
      } else if (activePlans.isNotEmpty) {
        _planId = activePlans.first['id'] as String?;
        _amountPaidController.text = '0';
      }

      setState(() {
        _detail = detail;
        _plans = activePlans;
        _loading = false;
      });
      _refreshEndPreview();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  void _refreshEndPreview() {
    if (_planId == null) return;
    final plan = _plans.where((p) => p['id'] == _planId).firstOrNull;
    if (plan == null) return;
    final days = plan['duration_days'] as int? ?? 30;
    setState(() => _computedEndDays = days);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  DateTime? get _computedEndDate {
    if (_computedEndDays == null) return null;
    return _startDate.add(Duration(days: _computedEndDays!));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _planId == null) return;

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save failed',
      action: () async {
        await repo.upsertMember(
          gymId: widget.gymId,
          memberId: widget.memberId,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          status: _memberStatus,
          emergencyContact: _emergencyController.text.trim(),
          notes: _notesController.text.trim(),
        );

        await repo.upsertMemberSubscription(
          gymId: widget.gymId,
          memberId: widget.memberId,
          subscriptionId: _subscriptionId,
          planId: _planId!,
          startDate: _startDate,
          paymentStatus: _paymentStatus,
          amountPaid: double.tryParse(_amountPaidController.text.trim()) ?? 0,
          subscriptionStatus: _subscriptionStatus,
        );
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member updated')),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _showCredentialsDialog({
    required String email,
    required String password,
    required String title,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share these login details with the member for the Gym Member app:'),
            const SizedBox(height: 12),
            SelectableText('Email: $email'),
            SelectableText('Password: $password'),
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
  }

  String? _validateLoginPassword(String? value) {
    if (value == null || value.length < 6) return 'Min 6 characters';
    return null;
  }

  Future<void> _updateMemberLogin() async {
    final password = _loginPasswordController.text;
    final confirm = _loginPasswordConfirmController.text;
    if (_validateLoginPassword(password) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final detail = _detail!;
    final repo = ref.read(gymRepositoryProvider);
    setState(() => _updatingLogin = true);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: detail.hasLogin ? 'Password update failed' : 'Create login failed',
      action: () async {
        final Map<String, dynamic> result;
        if (detail.hasLogin) {
          result = await repo.resetMemberPassword(
            gymId: widget.gymId,
            memberId: widget.memberId,
            password: password,
          );
        } else {
          final email = _emailController.text.trim();
          if (email.isEmpty || !email.contains('@')) {
            throw Exception('Enter a valid email in Profile before creating app login.');
          }
          result = await repo.provisionMemberLogin(
            gymId: widget.gymId,
            memberId: widget.memberId,
            password: password,
            email: email,
          );
        }

        if (!mounted) return;
        final credentials = result['credentials'] as Map<String, dynamic>?;
        final email = (credentials?['email'] ?? result['email'] ?? _emailController.text.trim())
            .toString();
        await _showCredentialsDialog(
          email: email,
          password: credentials?['password'] as String? ?? password,
          title: detail.hasLogin ? 'Password updated' : 'App login created',
        );
        _loginPasswordController.clear();
        _loginPasswordConfirmController.clear();
        await _load();
      },
    );

    if (!mounted) return;
    setState(() => _updatingLogin = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail.hasLogin ? 'Member password updated' : 'Member app login created',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final semantics = context.appColors;
    final dateFormat = DateFormat.yMMMd();
    final detail = _detail!;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.fullName),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (detail.hasLogin)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: semantics.accentLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android_rounded, size: 18, color: semantics.accentLime),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Has member app login · email cannot be changed here',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  label: 'Full name',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  readOnly: detail.hasLogin,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _memberStatus,
                  decoration: const InputDecoration(labelText: 'Member status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _memberStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _emergencyController,
                  label: 'Emergency contact',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes',
                ),
                if (detail.joinedOn != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Joined ${dateFormat.format(detail.joinedOn!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Member app login',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.hasLogin
                      ? 'Set a new password for the Gym Member app. The member signs in with their existing email.'
                      : 'Create app login credentials. Add a valid email above if missing, then set a password.',
                  style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _loginPasswordController,
                  label: detail.hasLogin ? 'New password' : 'Password',
                  obscureText: _obscureLoginPassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                  ),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _loginPasswordConfirmController,
                  label: 'Confirm password',
                  obscureText: _obscureLoginPasswordConfirm,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPasswordConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(
                      () => _obscureLoginPasswordConfirm = !_obscureLoginPasswordConfirm,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _updatingLogin ? null : _updateMemberLogin,
                  icon: _updatingLogin
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(detail.hasLogin ? Icons.lock_reset : Icons.person_add_alt_1),
                  label: Text(detail.hasLogin ? 'Update password' : 'Create app login'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Membership',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _plans.any((p) => p['id'] == _planId)
                      ? _planId
                      : (_plans.isNotEmpty ? _plans.first['id'] as String : null),
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: _plans
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text('${p['name']} · ₹${p['price']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _planId = v);
                    _refreshEndPreview();
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(
                    _computedEndDate != null
                        ? 'Ends ${dateFormat.format(_computedEndDate!)} (${_computedEndDays ?? 0} days)'
                        : dateFormat.format(_startDate),
                  ),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _subscriptionStatus,
                  decoration: const InputDecoration(labelText: 'Subscription status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _subscriptionStatus = v);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
