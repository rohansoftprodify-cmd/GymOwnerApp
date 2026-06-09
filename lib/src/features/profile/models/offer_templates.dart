import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/features/profile/models/offer_card_design.dart';

class OfferTemplate {
  const OfferTemplate({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.defaultBadge,
    required this.defaultTitle,
    required this.defaultDescription,
    required this.defaultButton,
    required this.defaultPositions,
    this.decorationIcon,
  });

  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final String defaultBadge;
  final String defaultTitle;
  final String defaultDescription;
  final String defaultButton;
  final Map<String, Offset> defaultPositions;
  final IconData? decorationIcon;

  OfferCardDesign toDesign({
    String? title,
    String? description,
    Map<String, Offset>? positions,
  }) {
    return OfferCardDesign(
      templateId: id,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      textColor: textColor,
      badgeText: defaultBadge,
      buttonText: defaultButton,
      positions: Map<String, Offset>.from(positions ?? defaultPositions),
      decorationIcon: decorationIcon?.codePoint.toString(),
    );
  }
}

class OfferTemplates {
  OfferTemplates._();

  static const _positionsClassic = {
    OfferCardDesign.elementBadge: Offset(0.05, 0.08),
    OfferCardDesign.elementTitle: Offset(0.05, 0.48),
    OfferCardDesign.elementDescription: Offset(0.05, 0.62),
    OfferCardDesign.elementDate: Offset(0.05, 0.82),
    OfferCardDesign.elementButton: Offset(0.68, 0.78),
  };

  static const _positionsCenterHero = {
    OfferCardDesign.elementBadge: Offset(0.30, 0.10),
    OfferCardDesign.elementTitle: Offset(0.08, 0.38),
    OfferCardDesign.elementDescription: Offset(0.08, 0.54),
    OfferCardDesign.elementDate: Offset(0.08, 0.78),
    OfferCardDesign.elementButton: Offset(0.62, 0.76),
  };

  static const _positionsBoldSale = {
    OfferCardDesign.elementBadge: Offset(0.05, 0.06),
    OfferCardDesign.elementTitle: Offset(0.05, 0.32),
    OfferCardDesign.elementDescription: Offset(0.05, 0.52),
    OfferCardDesign.elementDate: Offset(0.05, 0.80),
    OfferCardDesign.elementButton: Offset(0.65, 0.74),
  };

  static final List<OfferTemplate> all = [
    OfferTemplate(
      id: 'classic_teal',
      name: 'Classic Teal',
      primaryColor: const Color(0xFF2E7D6B),
      secondaryColor: const Color(0xFF4DD0E1),
      textColor: Colors.white,
      defaultBadge: 'LIMITED OFFER',
      defaultTitle: 'Summer Membership',
      defaultDescription: 'Join now and get 20% off your first month.',
      defaultButton: 'Claim Now',
      defaultPositions: _positionsClassic,
      decorationIcon: Icons.water_drop_outlined,
    ),
    OfferTemplate(
      id: 'sunset_burst',
      name: 'Sunset Burst',
      primaryColor: const Color(0xFFE65100),
      secondaryColor: const Color(0xFFFFB74D),
      textColor: Colors.white,
      defaultBadge: 'HOT DEAL',
      defaultTitle: 'Flash Sale — 48 Hours',
      defaultDescription: 'Unlimited classes + free diet consult this week only.',
      defaultButton: 'Grab Offer',
      defaultPositions: _positionsCenterHero,
      decorationIcon: Icons.local_fire_department_outlined,
    ),
    OfferTemplate(
      id: 'royal_purple',
      name: 'Royal Purple',
      primaryColor: const Color(0xFF5E35B1),
      secondaryColor: const Color(0xFF9575CD),
      textColor: Colors.white,
      defaultBadge: 'VIP ACCESS',
      defaultTitle: 'Premium Annual Plan',
      defaultDescription: 'Upgrade to annual billing and save ₹2,000.',
      defaultButton: 'Upgrade',
      defaultPositions: _positionsClassic,
      decorationIcon: Icons.diamond_outlined,
    ),
    OfferTemplate(
      id: 'bold_red',
      name: 'Bold Red Sale',
      primaryColor: const Color(0xFFC62828),
      secondaryColor: const Color(0xFFEF5350),
      textColor: Colors.white,
      defaultBadge: 'MEGA SALE',
      defaultTitle: '50% Off Personal Training',
      defaultDescription: 'Book 5 PT sessions — pay for 2. New members only.',
      defaultButton: 'Book Now',
      defaultPositions: _positionsBoldSale,
      decorationIcon: Icons.bolt_outlined,
    ),
    OfferTemplate(
      id: 'fresh_green',
      name: 'Fresh Green',
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFF81C784),
      textColor: Colors.white,
      defaultBadge: 'NEW MEMBER',
      defaultTitle: 'Bring a Friend Free',
      defaultDescription: 'Refer a friend and both get 7 days complimentary access.',
      defaultButton: 'Refer Now',
      defaultPositions: _positionsCenterHero,
      decorationIcon: Icons.favorite_outline,
    ),
    OfferTemplate(
      id: 'dark_premium',
      name: 'Dark Premium',
      primaryColor: const Color(0xFF1A1A2E),
      secondaryColor: const Color(0xFF16213E),
      textColor: const Color(0xFFF5F5F5),
      defaultBadge: 'EXCLUSIVE',
      defaultTitle: 'Elite Batch Enrollment',
      defaultDescription: 'Small-group strength program — limited seats available.',
      defaultButton: 'Enroll',
      defaultPositions: _positionsClassic,
      decorationIcon: Icons.fitness_center_outlined,
    ),
  ];

  static OfferTemplate byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.first,
    );
  }
}
