import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/auth/role_guards.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/utils/validators.dart';
import 'helpers/fakes.dart';
import 'package:repairconnect/shared/models/models.dart';

void main() {
  test('dev role derived from email', () {
    expect(devRoleForEmail('tech@x.co'), AppRoles.technician);
    expect(devRoleForEmail('admin@x.co'), AppRoles.admin);
    expect(devRoleForEmail('user@x.co'), AppRoles.customer);
  });

  test('strong password + otp + token validators', () {
    expect(strongPasswordValidator('short'), isNotNull);
    expect(strongPasswordValidator('password'), isNotNull);
    expect(strongPasswordValidator('pass1234'), isNull);
    expect(otpValidator('123'), isNotNull);
    expect(otpValidator('123456'), isNull);
    expect(resetTokenValidator('x'), isNotNull);
    expect(confirmPasswordValidator('a', 'b'), isNotNull);
    expect(confirmPasswordValidator('a', 'a'), isNull);
  });

  test('homeForRole maps roles', () {
    expect(homeForRole(AppRoles.customer), AppRoutes.customerHome);
    expect(homeForRole(AppRoles.technician), AppRoutes.techDashboard);
    expect(homeForRole(AppRoles.admin), AppRoutes.adminDashboard);
  });

  test('guardRoute enforces roles', () {
    const tech = User(
        id: 't', name: 'T', email: 't', role: AppRoles.technician);
    const cust = User(
        id: 'c', name: 'C', email: 'c', role: AppRoles.customer);
    const admin = User(
        id: 'a', name: 'A', email: 'a', role: AppRoles.admin);
    expect(guardRoute('/technician', cust), AppRoutes.customerHome);
    expect(guardRoute('/technician', tech), isNull);
    expect(guardRoute('/admin', tech), AppRoutes.customerHome);
    expect(guardRoute('/admin', admin), isNull);
    expect(guardRoute('/customer', null), AppRoutes.login);
    expect(guardRoute('/login', null), isNull);
    expect(guardRoute(AppRoutes.landing, tech),
        AppRoutes.techDashboard);
    expect(guardRoute(AppRoutes.splash, admin),
        AppRoutes.adminDashboard);
  });

  test('unverified tech cannot accept jobs', () {
    const pending = User(
        id: 't',
        name: 'T',
        email: 't',
        role: AppRoles.technician,
        techVerified: false,
        techStatus: 'PENDING');
    const approved = User(
        id: 't',
        name: 'T',
        email: 't',
        role: AppRoles.technician,
        techVerified: true,
        techStatus: 'APPROVED');
    expect(techAcceptAllowed(pending), false);
    expect(techAcceptAllowed(approved), true);
  });

  test('backend lowercase verification_status unlocks accept', () {
    // Laravel sends 'approved'/'pending'; the domain gate compares
    // against 'APPROVED'. Normalization happens at the parse boundary,
    // otherwise approved technicians are locked out of Accept.
    final approved = User.fromJson({
      'id': 5,
      'name': 'Dev Approved Tech',
      'email': 'approved.tech@repairconnect.dev',
      'role': 'technician',
      'tech_verified': true,
      'tech_status': 'approved',
    });
    expect(approved.techStatus, 'APPROVED');
    expect(techAcceptAllowed(approved), true);

    final pending = User.fromJson({
      'id': 6,
      'role': 'technician',
      'tech_verified': false,
      'tech_status': 'pending',
    });
    expect(pending.techStatus, 'PENDING');
    expect(techAcceptAllowed(pending), false);
  });
}
