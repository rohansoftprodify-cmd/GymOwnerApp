import 'package:flutter_test/flutter_test.dart';
import 'package:gym_owner_app/src/core/domain/report_calculations.dart';

void main() {
  test('pending amount cannot be negative', () {
    expect(pendingAmount(planPrice: 2500, amountPaid: 2800), 0);
  });

  test('pending amount is remaining value', () {
    expect(pendingAmount(planPrice: 2500, amountPaid: 1000), 1500);
  });

  test('attendance completion rate returns rounded percentage', () {
    expect(attendanceCompletionRate(totalCheckins: 21, totalCheckouts: 18), 86);
  });
}
