import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/features/technician/presentation/tech_extra_screens.dart';

void main() {
  test('earnings summarize paid vs pending', () {
    const entries = [
      EarningEntry('a', 100, true),
      EarningEntry('b', 50, false),
      EarningEntry('c', 200, true),
    ];
    final s = summarizeEarnings(entries);
    expect(s.current, 300);
    expect(s.pending, 50);
    expect(s.completed, 2);
  });
}
