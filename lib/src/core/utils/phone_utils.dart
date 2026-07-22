/// Normalize phone numbers for member Auth login (E.164, default +91 for 10-digit).
String? normalizeMemberPhone(String? raw) {
  if (raw == null) return null;
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.length == 10) return '+91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  if (digits.length >= 11 && digits.length <= 15) return '+$digits';
  return null;
}

bool isValidMemberPhone(String? raw) => normalizeMemberPhone(raw) != null;
