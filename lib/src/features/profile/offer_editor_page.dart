import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_card_design.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_templates.dart';
import 'package:gym_owner_app/src/features/profile/models/promotion_item.dart';
import 'package:gym_owner_app/src/features/profile/widgets/offer_editor_preview_panel.dart';
import 'package:intl/intl.dart';

class OfferEditorPage extends ConsumerStatefulWidget {
  const OfferEditorPage({
    super.key,
    required this.gymId,
    this.existing,
    this.initialTemplateId,
  });

  final String gymId;
  final PromotionItem? existing;
  final String? initialTemplateId;

  @override
  ConsumerState<OfferEditorPage> createState() => _OfferEditorPageState();
}

class _OfferEditorPageState extends ConsumerState<OfferEditorPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _badgeController = TextEditingController();
  final _buttonController = TextEditingController();
  late OfferCardDesign _design;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;
  String? _selectedElement;
  bool _saving = false;
  bool _draggingOnCard = false;

  static const _cardHeight = 168.0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _startDate = existing.startAt;
      _endDate = existing.endAt;
      _isActive = existing.isActive;
      _design = existing.cardDesign ?? OfferTemplates.byId('classic_teal').toDesign();
      _badgeController.text = _design.badgeText;
      _buttonController.text = _design.buttonText;
    } else {
      final template = OfferTemplates.byId(widget.initialTemplateId ?? 'classic_teal');
      _design = template.toDesign();
      _titleController.text = template.defaultTitle;
      _descriptionController.text = template.defaultDescription;
      _badgeController.text = template.defaultBadge;
      _buttonController.text = template.defaultButton;
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _badgeController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  OfferCardDesign _designForSave() {
    final badge = _badgeController.text.trim();
    final button = _buttonController.text.trim();
    return _design.copyWith(
      badgeText: badge.isEmpty ? 'LIMITED OFFER' : badge,
      buttonText: button.isEmpty ? 'Claim Now' : button,
    );
  }

  void _applyTemplate(OfferTemplate template) {
    setState(() {
      _design = template.toDesign(
        positions: Map<String, Offset>.from(template.defaultPositions),
      );
      if (widget.existing == null) {
        _titleController.text = template.defaultTitle;
        _descriptionController.text = template.defaultDescription;
      }
      _badgeController.text = template.defaultBadge;
      _buttonController.text = template.defaultButton;
      _selectedElement = null;
    });
  }

  void _setColor({Color? primary, Color? secondary, Color? text}) {
    setState(() {
      _design = _design.copyWith(
        primaryColor: primary,
        secondaryColor: secondary,
        textColor: text,
      );
    });
  }

  void _updateElementPosition(String id, Offset position) {
    setState(() {
      final next = Map<String, Offset>.from(_design.positions);
      next[id] = position;
      _design = _design.copyWith(positions: next);
    });
  }

  void _onPositionCommitted(String id, Offset position) => _updateElementPosition(id, position);

  String _elementLabel(String id) {
    return switch (id) {
      OfferCardDesign.elementBadge => 'Badge',
      OfferCardDesign.elementTitle => 'Title',
      OfferCardDesign.elementDescription => 'Description',
      OfferCardDesign.elementDate => 'Date',
      OfferCardDesign.elementButton => 'Button',
      _ => 'Element',
    };
  }

  Offset _elementPosition(String id) {
    return _design.positions[id] ??
        OfferTemplates.byId(_design.templateId).defaultPositions[id] ??
        const Offset(0.05, 0.5);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'Missing fields',
        error: 'Title and description are required.',
      );
      return;
    }
    if (!_endDate.isAfter(_startDate)) {
      await showAppErrorDialog(
        context,
        title: 'Invalid dates',
        error: 'End date must be after start date.',
      );
      return;
    }

    setState(() => _saving = true);

    final startUtc = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    final endUtc = DateTime.utc(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
    );

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Could not save offer',
      action: () => ref.read(gymRepositoryProvider).upsertPromotion(
            gymId: widget.gymId,
            id: widget.existing?.id,
            title: title,
            description: description,
            startAt: startUtc,
            endAt: endUtc,
            isActive: _isActive,
            cardDesign: _designForSave().toJson(),
          ),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Create offer' : 'Edit offer'),
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
      body: Column(
        children: [
          Material(
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Templates',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: OfferTemplates.all.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final template = OfferTemplates.all[index];
                      final selected = _design.templateId == template.id;
                      return GestureDetector(
                        onTap: () => _applyTemplate(template),
                        child: Column(
                          children: [
                            Container(
                              width: 112,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [template.primaryColor, template.secondaryColor],
                                ),
                                border: Border.all(
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  template.decorationIcon ?? Icons.local_offer_outlined,
                                  color: template.textColor.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Card layout',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_draggingOnCard)
                        Text(
                          'Dragging…',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tap a label on the card, then drag it — or use position sliders below.',
                    style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OfferEditorPreviewPanel(
                    key: ValueKey('${_design.templateId}_${_design.primaryColor.toARGB32()}'),
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    badgeController: _badgeController,
                    buttonController: _buttonController,
                    design: _design,
                    endAt: _endDate,
                    selectedElement: _selectedElement,
                    height: _cardHeight,
                    onElementSelected: (id) => setState(() => _selectedElement = id),
                    onElementPositionChanged: _onPositionCommitted,
                    onDragStart: () => setState(() => _draggingOnCard = true),
                    onDragEnd: () => setState(() => _draggingOnCard = false),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: _draggingOnCard
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_selectedElement != null) ...[
                  Text(
                    'Position — ${_elementLabel(_selectedElement!)}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fine-tune without dragging on the card.',
                    style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                  ),
                  const SizedBox(height: 8),
                  _PositionSlider(
                    label: 'Horizontal',
                    value: _elementPosition(_selectedElement!).dx,
                    onChanged: (v) => _updateElementPosition(
                      _selectedElement!,
                      Offset(v, _elementPosition(_selectedElement!).dy),
                    ),
                  ),
                  _PositionSlider(
                    label: 'Vertical',
                    value: _elementPosition(_selectedElement!).dy,
                    max: 0.88,
                    onChanged: (v) => _updateElementPosition(
                      _selectedElement!,
                      Offset(_elementPosition(_selectedElement!).dx, v),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Colors',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _ColorRow(
                  label: 'Primary',
                  color: _design.primaryColor,
                  presets: const [
                    Color(0xFF2E7D6B),
                    Color(0xFFE65100),
                    Color(0xFF5E35B1),
                    Color(0xFFC62828),
                    Color(0xFF2E7D32),
                    Color(0xFF1A1A2E),
                  ],
                  onChanged: (c) => _setColor(primary: c),
                ),
                const SizedBox(height: 8),
                _ColorRow(
                  label: 'Accent',
                  color: _design.secondaryColor,
                  presets: const [
                    Color(0xFF4DD0E1),
                    Color(0xFFFFB74D),
                    Color(0xFF9575CD),
                    Color(0xFFEF5350),
                    Color(0xFF81C784),
                    Color(0xFF16213E),
                  ],
                  onChanged: (c) => _setColor(secondary: c),
                ),
                const SizedBox(height: 8),
                _ColorRow(
                  label: 'Text',
                  color: _design.textColor,
                  presets: const [Colors.white, Color(0xFFF5F5F5), Colors.black],
                  onChanged: (c) => _setColor(text: c),
                ),
                const SizedBox(height: 16),
                Text(
                  'Offer copy',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _badgeController,
                  label: 'Badge text',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _buttonController,
                  label: 'Button text',
                ),
                const SizedBox(height: 16),
                Text(
                  'Schedule',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DateTile(
                  label: 'Starts',
                  value: dateFormat.format(_startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 8),
                _DateTile(
                  label: 'Ends',
                  value: dateFormat.format(_endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active offer'),
                    subtitle: Text(
                      'Inactive offers are hidden on the home screen',
                      style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(widget.existing == null ? 'Publish offer' : 'Update offer'),
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

class _PositionSlider extends StatelessWidget {
  const _PositionSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 0.92,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, max);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Slider(
            value: clamped,
            min: 0,
            max: max,
            divisions: (max * 50).round(),
            label: clamped.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.presets,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final List<Color> presets;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        ...presets.map(
          (preset) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(preset),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: preset,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: preset == color
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black26,
                    width: preset == color ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}
