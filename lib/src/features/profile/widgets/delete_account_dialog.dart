import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/auth/account_deletion_service.dart';
import 'package:gym_owner_app/src/core/auth/single_session_provider.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

Future<void> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  required String app,
  required String exitRoute,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DeleteAccountDialog(app: app),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(accountDeletionServiceProvider).deleteMyAccount(app: app);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('AuthException: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  try {
    await ref.read(singleSessionServiceProvider).signOutLocally();
  } catch (_) {}

  if (context.mounted) {
    context.go(exitRoute);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account was deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.app});

  final String app;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canDelete => _controller.text.trim().toUpperCase() == 'DELETE';

  List<String> get _bullets {
    if (widget.app == 'owner') {
      return const [
        'Your login and profile will be permanently deleted.',
        'You will lose access to the gym owner app immediately.',
        'Gym business records (members, sales, plans) remain with your gym.',
        'This action cannot be undone.',
      ];
    }
    return const [
      'Your login and app profile data will be permanently deleted.',
      'Fitness profile details you entered in the app will be removed.',
      'Your gym membership record may be kept by the gym for operations.',
      'This action cannot be undone.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: semantics.accentCoral, size: 28),
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This permanently deletes your app account per Apple and Google account deletion requirements.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final line in _bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodySmall?.copyWith(height: 1.35)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
            Text(
              'Type DELETE to confirm',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              enabled: !_deleting,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: semantics.accentCoral,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: !_canDelete || _deleting
              ? null
              : () async {
                  setState(() => _deleting = true);
                  Navigator.of(context).pop(true);
                },
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
