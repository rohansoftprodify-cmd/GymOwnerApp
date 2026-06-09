import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_card_design.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_templates.dart';
import 'package:intl/intl.dart';

class OfferCardPreview extends StatelessWidget {
  const OfferCardPreview({
    super.key,
    required this.title,
    required this.description,
    this.endAt,
    this.design,
    this.height = 148,
    this.margin = EdgeInsets.zero,
    this.editable = false,
    this.selectedElement,
    this.onElementPositionChanged,
    this.onElementSelected,
    this.onDragStart,
    this.onDragEnd,
    this.onClaim,
  });

  final String title;
  final String description;
  final DateTime? endAt;
  final OfferCardDesign? design;
  final double height;
  final EdgeInsetsGeometry margin;
  final bool editable;
  final String? selectedElement;
  final void Function(String elementId, Offset position)? onElementPositionChanged;
  final ValueChanged<String>? onElementSelected;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onClaim;

  OfferCardDesign get _design {
    if (design != null) return design!;
    return OfferTemplates.byId('classic_teal').toDesign();
  }

  IconData? _decorationIcon(OfferCardDesign d) {
    final raw = d.decorationIcon;
    if (raw == null) return Icons.water_drop_outlined;
    final codePoint = int.tryParse(raw);
    if (codePoint == null) return Icons.water_drop_outlined;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  @override
  Widget build(BuildContext context) {
    final d = _design;
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [d.primaryColor, d.secondaryColor],
          ),
          border: editable
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  width: 2,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: -12,
                  child: Icon(
                    _decorationIcon(d),
                    size: 120,
                    color: d.textColor.withValues(alpha: 0.12),
                  ),
                ),
                ..._buildElements(context, d, cardWidth, cardHeight),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildElements(
    BuildContext context,
    OfferCardDesign d,
    double cardWidth,
    double cardHeight,
  ) {
    final dateText = endAt == null
        ? 'Until —'
        : 'Until ${DateFormat.yMMMd().format(endAt!)}';

    final specs = <_ElementSpec>[
      _ElementSpec(
        id: OfferCardDesign.elementBadge,
        position: d.positions[OfferCardDesign.elementBadge] ?? const Offset(0.05, 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: d.textColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            d.badgeText,
            style: TextStyle(
              color: d.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      _ElementSpec(
        id: OfferCardDesign.elementTitle,
        position: d.positions[OfferCardDesign.elementTitle] ?? const Offset(0.05, 0.48),
        child: SizedBox(
          width: cardWidth * 0.88,
          child: Text(
            title.isEmpty ? 'Offer title' : title,
            style: TextStyle(
              color: d.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      _ElementSpec(
        id: OfferCardDesign.elementDescription,
        position: d.positions[OfferCardDesign.elementDescription] ?? const Offset(0.05, 0.62),
        child: SizedBox(
          width: cardWidth * 0.72,
          child: Text(
            description.isEmpty ? 'Offer description' : description,
            style: TextStyle(
              color: d.textColor.withValues(alpha: 0.92),
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      _ElementSpec(
        id: OfferCardDesign.elementDate,
        position: d.positions[OfferCardDesign.elementDate] ?? const Offset(0.05, 0.82),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 13, color: d.textColor.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: TextStyle(
                color: d.textColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      _ElementSpec(
        id: OfferCardDesign.elementButton,
        position: d.positions[OfferCardDesign.elementButton] ?? const Offset(0.68, 0.78),
        child: FilledButton(
          onPressed: editable ? null : onClaim,
          style: FilledButton.styleFrom(
            backgroundColor: d.textColor,
            foregroundColor: d.primaryColor.computeLuminance() > 0.5
                ? AppTheme.wellnessPrimary
                : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            d.buttonText,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
      ),
    ];

    return specs.map((spec) {
      final isSelected = editable && selectedElement == spec.id;

      Widget child = spec.child;
      if (editable) {
        child = _DraggableOfferElement(
          key: ValueKey(spec.id),
          elementId: spec.id,
          initialPosition: spec.position,
          cardSize: Size(cardWidth, cardHeight),
          isSelected: isSelected,
          onTap: () => onElementSelected?.call(spec.id),
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          onPositionCommitted: (position) => onElementPositionChanged?.call(spec.id, position),
          child: spec.child,
        );
      } else {
        final left = spec.position.dx.clamp(0.0, 0.92) * cardWidth;
        final top = spec.position.dy.clamp(0.0, 0.88) * cardHeight;
        return Positioned(left: left, top: top, child: child);
      }

      return child;
    }).toList();
  }
}

class _ElementSpec {
  const _ElementSpec({
    required this.id,
    required this.position,
    required this.child,
  });

  final String id;
  final Offset position;
  final Widget child;
}

class _DraggableOfferElement extends StatefulWidget {
  const _DraggableOfferElement({
    super.key,
    required this.elementId,
    required this.initialPosition,
    required this.cardSize,
    required this.isSelected,
    required this.onTap,
    this.onDragStart,
    this.onDragEnd,
    required this.onPositionCommitted,
    required this.child,
  });

  final String elementId;
  final Offset initialPosition;
  final Size cardSize;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final ValueChanged<Offset> onPositionCommitted;
  final Widget child;

  @override
  State<_DraggableOfferElement> createState() => _DraggableOfferElementState();
}

class _DraggableOfferElementState extends State<_DraggableOfferElement> {
  late Offset _position;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  void didUpdateWidget(covariant _DraggableOfferElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.initialPosition != widget.initialPosition) {
      _position = widget.initialPosition;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    widget.onDragStart?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        (_position.dx + details.delta.dx / widget.cardSize.width).clamp(0.0, 0.92),
        (_position.dy + details.delta.dy / widget.cardSize.height).clamp(0.0, 0.88),
      );
    });
  }

  void _finishDrag() {
    if (!_dragging) return;
    _dragging = false;
    widget.onDragEnd?.call();
    widget.onPositionCommitted(_position);
  }

  void _onPanEnd(DragEndDetails details) => _finishDrag();

  void _onPanCancel() => _finishDrag();

  @override
  Widget build(BuildContext context) {
    final left = _position.dx * widget.cardSize.width;
    final top = _position.dy * widget.cardSize.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: widget.isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5)
                : Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
