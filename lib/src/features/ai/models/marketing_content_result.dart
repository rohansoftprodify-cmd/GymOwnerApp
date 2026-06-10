class MarketingContentResult {
  const MarketingContentResult({
    required this.mode,
    required this.contentType,
    required this.festivalKey,
    required this.festivalLabel,
    required this.title,
    required this.body,
    required this.instagramCaption,
    required this.pushNotification,
    required this.hashtags,
    required this.cta,
    this.promptUsed,
  });

  final String mode;
  final String contentType;
  final String festivalKey;
  final String festivalLabel;
  final String title;
  final String body;
  final String instagramCaption;
  final MarketingPushCopy pushNotification;
  final List<String> hashtags;
  final String cta;
  final String? promptUsed;

  factory MarketingContentResult.fromMap(Map<String, dynamic> map) {
    final rawTags = map['hashtags'] as List<dynamic>? ?? [];
    final push = map['push_notification'];
    return MarketingContentResult(
      mode: map['mode'] as String? ?? 'template',
      contentType: map['content_type'] as String? ?? '',
      festivalKey: map['festival_key'] as String? ?? 'general',
      festivalLabel: map['festival_label'] as String? ?? 'Special',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      instagramCaption: map['instagram_caption'] as String? ?? map['body'] as String? ?? '',
      pushNotification: push is Map
          ? MarketingPushCopy.fromMap(Map<String, dynamic>.from(push))
          : const MarketingPushCopy(),
      hashtags: rawTags.map((e) => e.toString()).toList(),
      cta: map['cta'] as String? ?? '',
      promptUsed: map['prompt_used'] as String?,
    );
  }
}

class MarketingPushCopy {
  const MarketingPushCopy({this.title = '', this.body = ''});

  final String title;
  final String body;

  factory MarketingPushCopy.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MarketingPushCopy();
    return MarketingPushCopy(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
    );
  }
}
