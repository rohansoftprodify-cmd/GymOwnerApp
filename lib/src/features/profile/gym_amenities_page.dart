import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class GymAmenitiesPage extends ConsumerStatefulWidget {
  const GymAmenitiesPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymAmenitiesPage> createState() => _GymAmenitiesPageState();
}

class _GymAmenitiesPageState extends ConsumerState<GymAmenitiesPage> {
  bool _loading = true;
  bool _saving = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final gym = await ref.read(gymRepositoryProvider).gymById(widget.gymId);
      if (!mounted) return;
      final raw = gym?['amenities'];
      final keys = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
      setState(() {
        _selected
          ..clear()
          ..addAll(keys);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(gymRepositoryProvider).updateGymAmenities(
            gymId: widget.gymId,
            amenities: _selected.toList()..sort(),
          );
      ref.invalidate(gymProfileProvider(widget.gymId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facilities updated')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Save failed', error: error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym facilities'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'What does your gym offer?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select all facilities and classes members can see on your gym profile in the member app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: semantics.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final amenity in gymAmenitiesCatalog)
                      _AmenityChip(
                        amenity: amenity,
                        selected: _selected.contains(amenity.key),
                        onTap: () => _toggle(amenity.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_selected.length} selected — members see these on your public gym page.',
                          style: theme.textTheme.labelSmall?.copyWith(height: 1.35),
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

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.amenity,
    required this.selected,
    required this.onTap,
  });

  final GymAmenity amenity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Material(
      color: selected ? colorScheme.primary.withValues(alpha: 0.18) : semantics.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 156,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                amenity.icon,
                size: 22,
                color: selected ? colorScheme.primary : semantics.mutedText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  amenity.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? colorScheme.onSurface : semantics.mutedText,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
