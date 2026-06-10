import 'dart:convert';

import 'package:flutter/services.dart';

enum MarketingContentType {
  instagramPost,
  transformationCaption,
  festivalOffer,
  pushNotification,
}

extension MarketingContentTypeX on MarketingContentType {
  String get key => switch (this) {
        MarketingContentType.instagramPost => 'instagram_post',
        MarketingContentType.transformationCaption => 'transformation_caption',
        MarketingContentType.festivalOffer => 'festival_offer',
        MarketingContentType.pushNotification => 'push_notification',
      };

  String get label => switch (this) {
        MarketingContentType.instagramPost => 'Instagram post',
        MarketingContentType.transformationCaption => 'Transformation caption',
        MarketingContentType.festivalOffer => 'Festival offer',
        MarketingContentType.pushNotification => 'Push notification',
      };
}

class MarketingTemplateGenerator {
  MarketingTemplateGenerator._();

  static Map<String, dynamic>? _data;

  static Future<void> _ensureLoaded() async {
    if (_data != null) return;
    final raw = await rootBundle.loadString('assets/data/marketing_templates.json');
    _data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static String detectFestivalKey(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('diwali') || p.contains('deepavali')) return 'diwali';
    if (p.contains('holi')) return 'holi';
    if (p.contains('new year') || p.contains('newyear')) return 'new_year';
    if (p.contains('republic')) return 'republic_day';
    if (p.contains('independence') || p.contains('15 august') || p.contains('15th august')) {
      return 'independence_day';
    }
    if (p.contains('christmas') || p.contains('xmas')) return 'christmas';
    if (p.contains('summer')) return 'summer';
    return 'general';
  }

  static String _offerLine(String? offerHint) {
    final hint = offerHint?.trim();
    if (hint != null && hint.isNotEmpty) return hint;
    return 'Join now and save on annual & quarterly memberships';
  }

  static Future<Map<String, dynamic>> generate({
    required MarketingContentType contentType,
    required String gymName,
    required String prompt,
    String? offerHint,
    String? memberName,
  }) async {
    await _ensureLoaded();
    final festivals = Map<String, dynamic>.from(_data!['festivals'] as Map);
    final festivalKey = detectFestivalKey(prompt);
    final festival = Map<String, dynamic>.from(
      festivals[festivalKey] as Map? ?? festivals['general'] as Map,
    );
    final label = festival['label'] as String? ?? 'Special';
    final emoji = festival['emoji'] as String? ?? '💪';
    final hook = festival['offer_hook'] as String? ?? 'Membership Offer';
    final theme = festival['theme'] as String? ?? 'fitness and health';
    final offer = _offerLine(offerHint);
    final hashtags = [
      '#${gymName.replaceAll(' ', '')}',
      '#GymLife',
      '#FitnessMotivation',
      if (festivalKey != 'general') '#${label.replaceAll(' ', '')}Offer',
      '#MembershipDeal',
    ];

    final instagramCaption = switch (contentType) {
      MarketingContentType.instagramPost => '''
$emoji $hook at $gymName!

$offer

Celebrate $label with $theme. Train smarter, feel stronger, and start your transformation today.

📍 Visit us at $gymName
📩 DM us "JOIN" to claim your spot

${hashtags.join(' ')}''',
      MarketingContentType.transformationCaption => '''
${memberName ?? 'Our member'}'s journey at $gymName ${emoji}

Consistency + coaching + community = real results.
$offer

Ready for your transformation? Message us today.

${hashtags.join(' ')}''',
      MarketingContentType.festivalOffer => '''
$emoji $label MEMBERSHIP OFFER — $gymName

$hook
$offer

Perfect time to commit to your fitness goals. Limited slots this season.

Tap to claim → DM "OFFER" or visit the front desk.

${hashtags.join(' ')}''',
      MarketingContentType.pushNotification => '',
    };

    final pushTitle = switch (festivalKey) {
      'diwali' => '$emoji Diwali offer at $gymName',
      'new_year' => '$emoji New Year offer — $gymName',
      _ => '$emoji $hook — $gymName',
    };

    final pushBody = switch (contentType) {
      MarketingContentType.pushNotification =>
        '$offer. Tap to see $label membership deals at $gymName.',
      _ => '$offer. Limited-time $label promotion at $gymName — open the app to claim.',
    };

    final primaryBody = switch (contentType) {
      MarketingContentType.pushNotification => pushBody,
      MarketingContentType.transformationCaption => instagramCaption.trim(),
      _ => instagramCaption.trim(),
    };

    return {
      'mode': 'template',
      'content_type': contentType.key,
      'festival_key': festivalKey,
      'festival_label': label,
      'title': '$hook — $gymName',
      'body': primaryBody,
      'instagram_caption': contentType == MarketingContentType.pushNotification
          ? instagramCaption.trim().isEmpty
              ? '$emoji $hook at $gymName!\n\n$offer\n\n${hashtags.join(' ')}'
              : instagramCaption.trim()
          : instagramCaption.trim(),
      'push_notification': {
        'title': pushTitle,
        'body': pushBody,
      },
      'hashtags': hashtags,
      'cta': 'DM "JOIN" or visit $gymName front desk',
      'prompt_used': prompt.trim(),
    };
  }
}
