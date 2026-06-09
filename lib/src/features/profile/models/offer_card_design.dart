import 'dart:ui';

class OfferCardDesign {
  const OfferCardDesign({
    required this.templateId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.badgeText,
    required this.buttonText,
    required this.positions,
    this.decorationIcon,
  });

  final String templateId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final String badgeText;
  final String buttonText;
  final Map<String, Offset> positions;
  final String? decorationIcon;

  static const elementBadge = 'badge';
  static const elementTitle = 'title';
  static const elementDescription = 'description';
  static const elementDate = 'date';
  static const elementButton = 'button';

  OfferCardDesign copyWith({
    String? templateId,
    Color? primaryColor,
    Color? secondaryColor,
    Color? textColor,
    String? badgeText,
    String? buttonText,
    Map<String, Offset>? positions,
    String? decorationIcon,
  }) {
    return OfferCardDesign(
      templateId: templateId ?? this.templateId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textColor: textColor ?? this.textColor,
      badgeText: badgeText ?? this.badgeText,
      buttonText: buttonText ?? this.buttonText,
      positions: positions ?? Map<String, Offset>.from(this.positions),
      decorationIcon: decorationIcon ?? this.decorationIcon,
    );
  }

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        'primary_color': primaryColor.toARGB32(),
        'secondary_color': secondaryColor.toARGB32(),
        'text_color': textColor.toARGB32(),
        'badge_text': badgeText,
        'button_text': buttonText,
        if (decorationIcon != null) 'decoration_icon': decorationIcon,
        'positions': positions.map(
          (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
        ),
      };

  factory OfferCardDesign.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['positions'] as Map<String, dynamic>? ?? {};
    final positions = <String, Offset>{};
    for (final entry in rawPositions.entries) {
      final point = entry.value as Map<String, dynamic>;
      positions[entry.key] = Offset(
        (point['x'] as num?)?.toDouble() ?? 0,
        (point['y'] as num?)?.toDouble() ?? 0,
      );
    }

    return OfferCardDesign(
      templateId: json['template_id'] as String? ?? 'classic_teal',
      primaryColor: Color(json['primary_color'] as int? ?? 0xFF2E7D6B),
      secondaryColor: Color(json['secondary_color'] as int? ?? 0xFF4DD0E1),
      textColor: Color(json['text_color'] as int? ?? 0xFFFFFFFF),
      badgeText: json['badge_text'] as String? ?? 'LIMITED OFFER',
      buttonText: json['button_text'] as String? ?? 'Claim Now',
      positions: positions,
      decorationIcon: json['decoration_icon'] as String?,
    );
  }
}
