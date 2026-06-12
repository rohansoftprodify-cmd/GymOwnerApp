import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

class ProfileSettingsSearchBar extends StatefulWidget {
  const ProfileSettingsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<ProfileSettingsSearchBar> createState() => _ProfileSettingsSearchBarState();
}

class _ProfileSettingsSearchBarState extends State<ProfileSettingsSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final hasText = widget.controller.text.isNotEmpty;

    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search settings, AI tools, plans…',
        hintStyle: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
        prefixIcon: Icon(Icons.search_rounded, color: semantics.mutedText, size: 22),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear',
                onPressed: widget.onClear,
                icon: Icon(Icons.close_rounded, color: semantics.mutedText, size: 20),
              )
            : null,
        filled: true,
        fillColor: semantics.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
