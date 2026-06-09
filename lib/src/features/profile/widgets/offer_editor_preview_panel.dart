import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_card_design.dart';
import 'package:gym_owner_app/src/features/profile/widgets/offer_card_preview.dart';

/// Isolated preview that rebuilds on text changes without rebuilding the whole editor page.
class OfferEditorPreviewPanel extends StatefulWidget {
  const OfferEditorPreviewPanel({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.badgeController,
    required this.buttonController,
    required this.design,
    required this.endAt,
    required this.selectedElement,
    required this.onElementSelected,
    required this.onElementPositionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.height = 168,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController badgeController;
  final TextEditingController buttonController;
  final OfferCardDesign design;
  final DateTime endAt;
  final String? selectedElement;
  final ValueChanged<String> onElementSelected;
  final void Function(String elementId, Offset position) onElementPositionChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final double height;

  @override
  State<OfferEditorPreviewPanel> createState() => _OfferEditorPreviewPanelState();
}

class _OfferEditorPreviewPanelState extends State<OfferEditorPreviewPanel> {
  @override
  void initState() {
    super.initState();
    for (final c in [
      widget.titleController,
      widget.descriptionController,
      widget.badgeController,
      widget.buttonController,
    ]) {
      c.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [
      widget.titleController,
      widget.descriptionController,
      widget.badgeController,
      widget.buttonController,
    ]) {
      c.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  OfferCardDesign get _previewDesign {
    final badge = widget.badgeController.text.trim();
    final button = widget.buttonController.text.trim();
    return widget.design.copyWith(
      badgeText: badge.isEmpty ? 'LIMITED OFFER' : badge,
      buttonText: button.isEmpty ? 'Claim Now' : button,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OfferCardPreview(
      title: widget.titleController.text,
      description: widget.descriptionController.text,
      endAt: widget.endAt,
      design: _previewDesign,
      height: widget.height,
      editable: true,
      selectedElement: widget.selectedElement,
      onElementSelected: widget.onElementSelected,
      onElementPositionChanged: widget.onElementPositionChanged,
      onDragStart: widget.onDragStart,
      onDragEnd: widget.onDragEnd,
    );
  }
}
