import 'package:flutter_test/flutter_test.dart';
import 'package:gym_owner_app/src/core/domain/attendance_rules.dart';

void main() {
  test('can check in when no open session exists', () {
    expect(canCheckIn(hasOpenSession: false), isTrue);
  });

  test('cannot check in when session already open', () {
    expect(canCheckIn(hasOpenSession: true), isFalse);
  });

  test('can check out only with an open session', () {
    expect(canCheckOut(hasOpenSession: true), isTrue);
    expect(canCheckOut(hasOpenSession: false), isFalse);
  });
}
