export type MarketingContentType =
  | 'instagram_post'
  | 'transformation_caption'
  | 'festival_offer'
  | 'push_notification';

export type MarketingResult = {
  mode: 'template';
  content_type: MarketingContentType;
  festival_key: string;
  festival_label: string;
  title: string;
  body: string;
  instagram_caption: string;
  push_notification: { title: string; body: string };
  hashtags: string[];
  cta: string;
  prompt_used: string;
};

const festivals: Record<string, { label: string; emoji: string; hook: string; theme: string }> = {
  diwali: { label: 'Diwali', emoji: '🪔', hook: 'Diwali Fitness Dhamaka', theme: 'festival of lights and new beginnings' },
  holi: { label: 'Holi', emoji: '🎨', hook: 'Holi Health Splash', theme: 'colour, energy, and celebration' },
  new_year: { label: 'New Year', emoji: '🎉', hook: 'New Year, New You', theme: 'fresh start and resolutions' },
  republic_day: { label: 'Republic Day', emoji: '🇮🇳', hook: 'Fit India Offer', theme: 'discipline and strength' },
  independence_day: { label: 'Independence Day', emoji: '🇮🇳', hook: 'Azadi from Excuses', theme: 'freedom through fitness' },
  christmas: { label: 'Christmas', emoji: '🎄', hook: 'Christmas Transformation Gift', theme: 'gifting health' },
  summer: { label: 'Summer', emoji: '☀️', hook: 'Summer Shred Challenge', theme: 'summer fitness push' },
  general: { label: 'Special', emoji: '💪', hook: 'Limited-Time Membership Offer', theme: 'exclusive membership value' },
};

export function detectFestivalKey(prompt: string): string {
  const p = prompt.toLowerCase();
  if (p.includes('diwali') || p.includes('deepavali')) return 'diwali';
  if (p.includes('holi')) return 'holi';
  if (p.includes('new year') || p.includes('newyear')) return 'new_year';
  if (p.includes('republic')) return 'republic_day';
  if (p.includes('independence') || p.includes('15 august')) return 'independence_day';
  if (p.includes('christmas') || p.includes('xmas')) return 'christmas';
  if (p.includes('summer')) return 'summer';
  return 'general';
}

export function generateFromTemplate(input: {
  contentType: MarketingContentType;
  gymName: string;
  prompt: string;
  offerHint?: string;
  memberName?: string;
}): MarketingResult {
  const festivalKey = detectFestivalKey(input.prompt);
  const festival = festivals[festivalKey] ?? festivals.general;
  const offer = input.offerHint?.trim() || 'Join now and save on annual & quarterly memberships';
  const hashtags = [
    `#${input.gymName.replace(/\s+/g, '')}`,
    '#GymLife',
    '#FitnessMotivation',
    ...(festivalKey !== 'general' ? [`#${festival.label.replace(/\s+/g, '')}Offer`] : []),
    '#MembershipDeal',
  ];

  const instagramCaption = (() => {
    switch (input.contentType) {
      case 'transformation_caption':
        return `${input.memberName ?? 'Our member'}'s journey at ${input.gymName} ${festival.emoji}\n\nConsistency + coaching = results.\n${offer}\n\n${hashtags.join(' ')}`;
      case 'festival_offer':
        return `${festival.emoji} ${festival.label} MEMBERSHIP OFFER — ${input.gymName}\n\n${festival.hook}\n${offer}\n\n${hashtags.join(' ')}`;
      case 'push_notification':
        return `${festival.emoji} ${festival.hook} at ${input.gymName}!\n\n${offer}\n\n${hashtags.join(' ')}`;
      default:
        return `${festival.emoji} ${festival.hook} at ${input.gymName}!\n\n${offer}\n\nCelebrate ${festival.label} with ${festival.theme}.\n\n${hashtags.join(' ')}`;
    }
  })();

  const pushTitle = `${festival.emoji} ${festival.hook} — ${input.gymName}`;
  const pushBody = `${offer}. Limited-time ${festival.label} promotion at ${input.gymName}.`;

  const body = input.contentType === 'push_notification' ? pushBody : instagramCaption;

  return {
    mode: 'template',
    content_type: input.contentType,
    festival_key: festivalKey,
    festival_label: festival.label,
    title: `${festival.hook} — ${input.gymName}`,
    body,
    instagram_caption: instagramCaption,
    push_notification: { title: pushTitle, body: pushBody },
    hashtags,
    cta: `DM "JOIN" or visit ${input.gymName} front desk`,
    prompt_used: input.prompt.trim(),
  };
}
