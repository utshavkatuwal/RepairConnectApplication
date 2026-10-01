// Central app constants: roles, job states, routes, API paths.
// Figma remains visual source of truth; these are non-visual contracts.
class AppRoles {
  static const customer = 'CUSTOMER';
  static const technician = 'TECHNICIAN';
  static const admin = 'ADMIN';
  static const all = [customer, technician, admin];
}

class JobStatus {
  static const requested = 'REQUESTED';
  static const accepted = 'ACCEPTED';
  static const scheduled = 'SCHEDULED';
  static const enRoute = 'EN_ROUTE';
  static const arrived = 'ARRIVED';
  static const inProgress = 'IN_PROGRESS';
  static const completed = 'COMPLETED';
  static const cancelled = 'CANCELLED';
  static const disputed = 'DISPUTED';

  static const ordered = [
    requested,
    accepted,
    scheduled,
    enRoute,
    arrived,
    inProgress,
    completed,
  ];

  /// Valid forward transitions. Cancellation allowed from pre-completion states.
  static const transitions = <String, List<String>>{
    requested: [accepted, cancelled],
    // Mirrors backend App\Enums\JobStatus: accepted ->
    // technician_arriving -> in_progress -> completed (no separate
    // scheduled/arrived job states; those only exist as display aliases).
    accepted: [enRoute, cancelled],
    scheduled: [enRoute, cancelled],
    enRoute: [inProgress, cancelled],
    arrived: [inProgress, cancelled],
    inProgress: [completed, disputed],
    completed: [disputed],
    disputed: [],
    cancelled: [],
  };

  static bool canTransition(String from, String to) =>
      transitions[from]?.contains(to) ?? false;
}

class PaymentStatus {
  static const pending = 'PENDING';
  static const processing = 'PROCESSING';
  static const succeeded = 'SUCCEEDED';
  static const failed = 'FAILED';
  static const refunded = 'REFUNDED';
}

class ApiRoutes {
  static const authLogin = '/api/v1/auth/login';
  static const authRegister = '/api/v1/auth/register';
  static const authLogout = '/api/v1/auth/logout';
  static const authRefresh = '/api/v1/auth/refresh';
  static const authForgot = '/api/v1/auth/forgot-password';
  static const authReset = '/api/v1/auth/reset-password';
  static const authVerifySend = '/api/v1/auth/verify/send';
  static const authVerify = '/api/v1/auth/verify';
  static const me = '/api/v1/auth/me';
  static const categories = '/api/v1/specialties';
  static const services = '/api/v1/specialties';
  static const technicians = '/api/v1/technicians';
  static const serviceRequests = '/api/v1/service-requests';
  static const bookings = '/api/v1/jobs';
  static const conversations = '/api/v1/conversations';
  static const messages = '/api/v1/messages';
  static const notifications = '/api/v1/notifications';
  static const payments = '/api/v1/payments';
  static const transactions = '/api/v1/transactions';
  static const invoices = '/api/v1/invoices';
  static const reviews = '/api/v1/reviews';
  static const complaints = '/api/v1/complaints';
}

class AppRoutes {
  static const splash = '/';
  static const landing = '/landing';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const verify = '/verify';
  static const role = '/role';
  static const customerHome = '/customer';
  static const discovery = '/customer/discovery';
  static const categories = '/customer/categories';
  static const serviceDetail = '/customer/service';
  static const techDetail = '/customer/tech';
  static const history = '/customer/history';
  static const notifications = '/notifications';
  static const createRequest = '/customer/request';
  static const bookingDetail = '/booking';
  static const chat = '/chat';
  static const techDashboard = '/technician';
  static const techRequests = '/technician/requests';
  static const techProfile = '/technician/profile';
  static const techEarnings = '/technician/earnings';
  static const techAvailability = '/technician/availability';
  static const techRegister = '/technician/register';
  static const adminDashboard = '/admin';
  static const adminUsers = '/admin/users';
  static const adminVerify = '/admin/verify';
  static const adminServices = '/admin/services';
  static const adminJobs = '/admin/jobs';
  static const adminPayments = '/admin/payments';
  static const adminWithdrawals = '/admin/withdrawals';
  static const adminComplaints = '/admin/complaints';
  static const adminAudit = '/admin/audit';
  static const designSystem = '/design-system';
  static const profile = '/profile';
}
