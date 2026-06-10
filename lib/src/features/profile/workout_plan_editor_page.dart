import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/workout_models.dart';
import 'package:gym_owner_app/src/features/profile/widgets/ai_generate_workout_dialog.dart';

class WorkoutPlanEditorPage extends ConsumerStatefulWidget {
  const WorkoutPlanEditorPage({
    super.key,
    required this.gymId,
    this.planId,
    required this.categories,
  });

  final String gymId;
  final String? planId;
  final List<WorkoutCategoryItem> categories;

  @override
  ConsumerState<WorkoutPlanEditorPage> createState() => _WorkoutPlanEditorPageState();
}

class _WorkoutPlanEditorPageState extends ConsumerState<WorkoutPlanEditorPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _sessionsPerWeekController = TextEditingController(text: '4');
  final _durationWeeksController = TextEditingController(text: '4');
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  String? _categoryId;
  String? _savedPlanId;
  String _experienceLevel = 'beginner';
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  bool _generatingAi = false;
  List<WorkoutSessionItem> _sessions = [];

  bool get _planPersisted => _savedPlanId != null;

  @override
  void initState() {
    super.initState();
    _savedPlanId = widget.planId;
    if (widget.categories.isNotEmpty) _categoryId = widget.categories.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    _sessionsPerWeekController.dispose();
    _durationWeeksController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (widget.planId != null) {
        final repo = ref.read(gymRepositoryProvider);
        final plans = await repo.workoutPlans(widget.gymId);
        final plan = plans.where((p) => p['id'] == widget.planId).firstOrNull;
        if (plan == null) throw Exception('Plan not found');
        final sessions = (await repo.workoutSessions(widget.gymId, widget.planId!))
            .map(WorkoutSessionItem.fromMap)
            .toList();
        if (!mounted) return;
        setState(() {
          _nameController.text = plan['name'] as String? ?? '';
          _descriptionController.text = plan['description'] as String? ?? '';
          _equipmentController.text = plan['equipment_hint'] as String? ?? '';
          _sessionsPerWeekController.text = '${plan['sessions_per_week'] ?? 4}';
          _durationWeeksController.text = '${plan['duration_weeks'] ?? 4}';
          _experienceLevel = plan['experience_level'] as String? ?? 'beginner';
          _categoryId = plan['category_id'] as String?;
          _ageController.text = plan['member_age']?.toString() ?? '';
          _weightController.text = plan['member_weight_kg']?.toString() ?? '';
          _isActive = plan['is_active'] as bool? ?? true;
          _sessions = sessions;
        });
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: e);
    }
  }

  void _applyAiPlan(Map<String, dynamic> plan) {
    setState(() {
      if (plan['name'] != null) _nameController.text = '${plan['name']}';
      if (plan['description'] != null) _descriptionController.text = '${plan['description']}';
      if (plan['equipment_hint'] != null) _equipmentController.text = '${plan['equipment_hint']}';
      if (plan['sessions_per_week'] != null) {
        _sessionsPerWeekController.text = '${plan['sessions_per_week']}';
      }
      if (plan['duration_weeks'] != null) {
        _durationWeeksController.text = '${plan['duration_weeks']}';
      }
      if (plan['experience_level'] != null) {
        _experienceLevel = plan['experience_level'] as String;
      }

      final rawSessions = plan['sessions'] as List<dynamic>? ?? [];
      _sessions = rawSessions.asMap().entries.map((entry) {
        final session = Map<String, dynamic>.from(entry.value as Map);
        final rawExercises = session['exercises'] as List<dynamic>? ?? [];
        return WorkoutSessionItem(
          dayLabel: session['day_label'] as String? ?? 'Day ${entry.key + 1}',
          dayNumber: session['day_number'] as int? ?? entry.key + 1,
          guidance: session['guidance'] as String?,
          sortOrder: entry.key,
          exercises: rawExercises.asMap().entries.map((exEntry) {
            final ex = Map<String, dynamic>.from(exEntry.value as Map);
            return WorkoutSessionExerciseItem(
              exerciseName: ex['exercise_name'] as String? ?? '',
              sets: ex['sets'] as int? ?? 3,
              reps: ex['reps'] as int? ?? 10,
              restSeconds: ex['rest_seconds'] as int?,
              notes: ex['notes'] as String?,
              sortOrder: exEntry.key,
            );
          }).toList(),
        );
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _planPersisted
              ? 'Plan applied — tap Save to update sessions'
              : 'Plan applied — save to store sessions',
        ),
      ),
    );
  }

  Future<void> _openAiGenerate() async {
    if (_generatingAi) return;
    setState(() => _generatingAi = true);
    final plan = await showAiGenerateWorkoutDialog(
      context,
      ref,
      gymId: widget.gymId,
      categories: widget.categories,
      categoryId: _categoryId,
    );
    if (!mounted) return;
    setState(() => _generatingAi = false);
    if (plan != null) _applyAiPlan(plan);
  }

  Future<void> _save() async {
    final categoryId = _categoryId;
    if (categoryId == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and goal are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final row = await repo.upsertWorkoutPlan(
        gymId: widget.gymId,
        id: _savedPlanId,
        categoryId: categoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        durationWeeks: int.tryParse(_durationWeeksController.text.trim()) ?? 4,
        sessionsPerWeek: int.tryParse(_sessionsPerWeekController.text.trim()) ?? 4,
        experienceLevel: _experienceLevel,
        equipmentHint: _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        memberAge: int.tryParse(_ageController.text.trim()),
        memberWeightKg: double.tryParse(_weightController.text.trim()),
        isActive: _isActive,
      );
      _savedPlanId = row['id'] as String;

      if (_sessions.isNotEmpty) {
        final sessionsPayload = _sessions.asMap().entries.map((entry) {
          final session = entry.value;
          return {
            'day_label': session.dayLabel,
            'day_number': session.dayNumber,
            'guidance': session.guidance,
            'exercises': session.exercises
                .map((ex) => {
                      'exercise_name': ex.exerciseName,
                      'sets': ex.sets,
                      'reps': ex.reps,
                      if (ex.restSeconds != null) 'rest_seconds': ex.restSeconds,
                      if (ex.notes != null) 'notes': ex.notes,
                    })
                .toList(),
          };
        }).toList();
        await repo.applyWorkoutPlanSessions(
          workoutPlanId: _savedPlanId!,
          sessions: sessionsPayload,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Save failed', error: e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId == null ? 'New workout plan' : 'Edit workout plan'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.tonalIcon(
                  onPressed: _generatingAi ? null : _openAiGenerate,
                  icon: _generatingAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_generatingAi ? 'Generating…' : 'AI Workout Coach'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: widget.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.goalInfo?.title ?? c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _nameController, label: 'Plan name'),
                const SizedBox(height: 8),
                AppTextField(controller: _descriptionController, label: 'Description'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _experienceLevel,
                  decoration: const InputDecoration(labelText: 'Experience level'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  ],
                  onChanged: (v) => setState(() => _experienceLevel = v ?? 'beginner'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _sessionsPerWeekController,
                        label: 'Sessions / week',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _durationWeeksController,
                        label: 'Weeks',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: AppTextField(controller: _ageController, label: 'Age')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _equipmentController, label: 'Equipment'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sessions (${_sessions.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (_sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Use AI Workout Coach to generate sessions.',
                      style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                    ),
                  )
                else
                  ..._sessions.map(
                    (session) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ExpansionTile(
                        title: Text(session.dayLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${session.exercises.length} exercises'),
                        children: [
                          if (session.guidance != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(session.guidance!, style: theme.textTheme.bodySmall),
                            ),
                          ...session.exercises.map(
                            (ex) => ListTile(
                              dense: true,
                              title: Text(ex.exerciseName),
                              subtitle: Text(
                                '${ex.sets} × ${ex.reps}'
                                '${ex.restSeconds != null ? ' · ${ex.restSeconds}s rest' : ''}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
