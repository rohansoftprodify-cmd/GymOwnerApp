import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/exercise_item.dart';
import 'package:image_picker/image_picker.dart';

class ExerciseFormPage extends ConsumerStatefulWidget {
  const ExerciseFormPage({
    super.key,
    required this.gymId,
    this.exercise,
    required this.categories,
  });

  final String gymId;
  final ExerciseItem? exercise;
  final List<ExerciseCategoryItem> categories;

  @override
  ConsumerState<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends ConsumerState<ExerciseFormPage> {
  final _nameController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _precautionsController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');

  String? _categoryId;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _saving = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    if (e != null) {
      _nameController.text = e.name;
      _benefitsController.text = e.benefits ?? '';
      _precautionsController.text = e.precautions ?? '';
      _setsController.text = '${e.defaultSets}';
      _repsController.text = '${e.defaultReps}';
      _categoryId = e.categoryId;
      _existingImageUrl = e.imageUrl;
      _isActive = e.isActive;
    } else if (widget.categories.isNotEmpty) {
      _categoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _benefitsController.dispose();
    _precautionsController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _existingImageUrl = null;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final benefits = _benefitsController.text.trim();
    final precautions = _precautionsController.text.trim();
    final sets = int.tryParse(_setsController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());

    if (name.isEmpty) {
      await showAppErrorDialog(context, title: 'Missing name', error: 'Enter exercise name.');
      return;
    }
    if (_categoryId == null || _categoryId!.isEmpty) {
      await showAppErrorDialog(context, title: 'Missing category', error: 'Select a category.');
      return;
    }
    if (sets == null || sets <= 0 || reps == null || reps <= 0) {
      await showAppErrorDialog(
        context,
        title: 'Invalid sets/reps',
        error: 'Sets and reps must be positive numbers.',
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save failed',
      action: () async {
        final row = await repo.upsertExercise(
          gymId: widget.gymId,
          id: widget.exercise?.id,
          categoryId: _categoryId!,
          name: name,
          imagePath: widget.exercise?.imagePath,
          benefits: benefits.isEmpty ? null : benefits,
          precautions: precautions.isEmpty ? null : precautions,
          defaultSets: sets,
          defaultReps: reps,
          isActive: _isActive,
        );
        final exerciseId = row['id'] as String;

        if (_imageBytes != null) {
          final path = await repo.uploadExerciseImage(
            gymId: widget.gymId,
            exerciseId: exerciseId,
            bytes: _imageBytes!,
          );
          await repo.upsertExercise(
            gymId: widget.gymId,
            id: exerciseId,
            categoryId: _categoryId!,
            name: name,
            imagePath: path,
            benefits: benefits.isEmpty ? null : benefits,
            precautions: precautions.isEmpty ? null : precautions,
            defaultSets: sets,
            defaultReps: reps,
            isActive: _isActive,
          );
        }
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Add exercise' : 'Edit exercise'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : _existingImageUrl != null
                            ? Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imagePlaceholder(colorScheme),
                              )
                            : _imagePlaceholder(colorScheme),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to add or change photo',
                    style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _nameController,
                  label: 'Exercise name',
                  prefixIcon: const Icon(Icons.fitness_center_outlined, size: 18),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: widget.categories.any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Category (muscle group)',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                  ),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _setsController,
                        label: 'Sets',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.repeat_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: _repsController,
                        label: 'Reps',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _benefitsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Benefits',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.thumb_up_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _precautionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Precautions',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.warning_amber_outlined, size: 18),
                  ),
                ),
                if (widget.exercise != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active exercise', style: TextStyle(fontSize: 13)),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save exercise'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: colorScheme.primary),
          const SizedBox(height: 8),
          const Text('Add exercise image'),
        ],
      ),
    );
  }
}
