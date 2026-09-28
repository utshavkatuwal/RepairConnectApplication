import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/features/admin/presentation/admin_extra_screens.dart';

void main() {
  test('admin user filter by query and role', () {
    const all = [
      AdminUser('u-1', 'Ann', 'CUSTOMER', true),
      AdminUser('u-2', 'Bob Tech', 'TECHNICIAN', false),
    ];
    expect(filterAdminUsers(all, q: 'ann').length, 1);
    expect(filterAdminUsers(all, role: 'TECHNICIAN').length, 1);
    expect(filterAdminUsers(all, activeOnly: true).length, 1);
  });

  test('verification decision mapping', () {
    expect(decideVerification('approve'), 'APPROVED');
    expect(decideVerification('reject'), 'REJECTED');
    expect(decideVerification('x'), 'CORRECTION');
  });
}
