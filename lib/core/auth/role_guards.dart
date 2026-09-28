import '../constants/app_constants.dart';
import '../../shared/models/models.dart';

/// Centralized role/verification gates (§35). Backend enforces; UI mirrors
/// to prevent confusion. Never trust client role for authorization.
String homeForRole(String role) {
  switch (role) {
    case AppRoles.technician:
      return AppRoutes.techDashboard;
    case AppRoles.admin:
      return AppRoutes.adminDashboard;
    default:
      return AppRoutes.customerHome;
  }
}

/// Returns redirect target or null if access granted.
String? guardRoute(String location, User? user) {
  const pub = [
    AppRoutes.splash,
    AppRoutes.landing,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgot,
    AppRoutes.verify,
    AppRoutes.reset,
    AppRoutes.role,
  ];
  if (user == null) {
    if (pub.contains(location) ||
        location.startsWith(AppRoutes.designSystem) ||
        location.startsWith(AppRoutes.reset)) {
      return null;
    }
    return AppRoutes.login;
  }
  if (location.startsWith('/technician') &&
      user.role != AppRoles.technician &&
      user.role != AppRoles.admin) {
    return AppRoutes.customerHome;
  }
  if (location.startsWith('/admin') && user.role != AppRoles.admin) {
    return AppRoutes.customerHome;
  }
  if (location == AppRoutes.login ||
      location == AppRoutes.signup ||
      location == AppRoutes.landing ||
      location == AppRoutes.splash) {
    return homeForRole(user.role);
  }
  return null;
}

/// Verification-gated actions: unverified techs see pending state, no accept.
bool techAcceptAllowed(User u) => u.canAcceptJobs;
