import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_card_design.dart';
import 'package:gym_owner_app/src/features/profile/widgets/offer_card_preview.dart';

class ExclusiveOfferCard extends StatelessWidget {
  const ExclusiveOfferCard({
    super.key,
    required this.offer,
    this.height = 148,
    this.margin = EdgeInsets.zero,
    this.onClaim,
  });

  final Map<String, dynamic> offer;
  final double height;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final rawDesign = offer['card_design'];
    final design = rawDesign is Map
        ? OfferCardDesign.fromJson(Map<String, dynamic>.from(rawDesign))
        : null;
    final endAt = DateTime.tryParse(offer['end_at'] as String? ?? '');

    return OfferCardPreview(
      title: offer['title'] as String? ?? 'Deal',
      description: offer['description'] as String? ?? '',
      endAt: endAt,
      design: design,
      height: height,
      margin: margin,
      onClaim: onClaim,
    );
  }
}
