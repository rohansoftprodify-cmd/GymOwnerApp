import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';
import 'package:gym_owner_app/src/features/profile/widgets/amenity_group_config.dart';
import 'package:gym_owner_app/src/features/profile/widgets/amenity_select_tile.dart';

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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        const SnackBar(
          content: Text('Facilities updated'),
          behavior: SnackBarBehavior.floating,
        ),
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

  void _selectAllVisible() {
    final groups = visibleAmenityGroups(_searchQuery);
    setState(() {
      for (final group in groups) {
        _selected.addAll(group.keys);
      }
    });
  }

  void _clearAll() {
    setState(_selected.clear);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final groups = visibleAmenityGroups(_searchQuery);
    final totalCatalog = gymAmenitiesCatalog.length;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gym facilities'),
        centerTitle: true,
      ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Save (no facilities selected)'
                            : 'Save ${_selected.length} facilit${_selected.length == 1 ? 'y' : 'ies'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _FacilitiesHero(
                          selectedCount: _selected.length,
                          totalCount: totalCatalog,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search facilities…',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: semantics.mutedText,
                              size: 22,
                            ),
                            suffixIcon: isSearching
                                ? IconButton(
                                    onPressed: _clearSearch,
                                    icon: Icon(Icons.close_rounded, color: semantics.mutedText),
                                  )
                                : null,
                            filled: true,
                            fillColor: semantics.cardBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isSearching
                                    ? '${groups.fold<int>(0, (n, g) => n + g.keys.length)} matches'
                                    : '${_selected.length} of $totalCatalog selected',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: semantics.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _selectAllVisible,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Select all', style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: _selected.isEmpty ? null : _clearAll,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Clear', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        if (groups.isEmpty) ...[
                          const SizedBox(height: 32),
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: semantics.mutedText.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No facilities match “${_searchQuery.trim()}”',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                          ),
                        ],
                        for (final group in groups) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(group.icon, size: 17, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                group.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${group.keys.where(_selected.contains).length}/${group.keys.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: semantics.mutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 400 ? 3 : 2;
                              final amenities = amenitiesForGroup(group);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.22,
                                ),
                                itemCount: amenities.length,
                                itemBuilder: (context, index) {
                                  final amenity = amenities[index];
                                  return AmenitySelectTile(
                                    amenity: amenity,
                                    selected: _selected.contains(amenity.key),
                                    onTap: () => _toggle(amenity.key),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.visibility_outlined, color: colorScheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Selected facilities appear on your gym profile in the member app — gym details, directory, and explore.',
                                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FacilitiesHero extends StatelessWidget {
  const _FacilitiesHero({
    required this.selectedCount,
    required this.totalCount,
  });

  final int selectedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final progress = totalCount == 0 ? 0.0 : selectedCount / totalCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -14,
            child: Icon(
              Icons.category_rounded,
              size: 100,
              color: colorScheme.onPrimary.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.storefront_rounded, color: colorScheme.onPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What does your gym offer?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to toggle — members see these on your public profile.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: semantics.accentLime,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$selectedCount of $totalCount facilities active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
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
