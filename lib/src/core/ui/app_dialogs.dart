import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing message from API / RPC errors.
String apiErrorMessage(Object error) {
  if (error is PostgrestException) {
    return error.message;
  }
  if (error is AuthException) {
    return error.message;
  }
  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  return error.toString();
}

Future<void> showAppErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.error_outline_rounded, color: Theme.of(dialogContext).colorScheme.error),
      title: Text(title),
      content: Text(apiErrorMessage(error)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action]; shows error dialog on failure. Returns true if succeeded.
Future<bool> runWithErrorDialog(
  BuildContext context, {
  required String errorTitle,
  required Future<void> Function() action,
}) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      await showAppErrorDialog(context, title: errorTitle, error: error);
    }
    return false;
  }
}
