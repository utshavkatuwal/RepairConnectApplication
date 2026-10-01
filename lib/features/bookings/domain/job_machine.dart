import '../../../core/constants/app_constants.dart';

/// Booking/job state machine (§9, §35). Single source of truth.
/// Server enforces authoritatively; UI mirrors for fast, honest UX.
///
/// Actor rules:
/// - REQUESTED→ACCEPTED: TECHNICIAN (verified) or ADMIN.
/// - ACCEPTED→SCHEDULED, SCHEDULED→EN_ROUTE, EN_ROUTE→ARRIVED,
///   ARRIVED→IN_PROGRESS, IN_PROGRESS→COMPLETED: assigned TECHNICIAN or ADMIN.
/// - CANCELLED: CUSTOMER (own request, pre-completion) or assigned
///   TECHNICIAN or ADMIN. Reason required.
/// - DISPUTED: CUSTOMER or TECHNICIAN participant, or ADMIN. Reason required.
/// - Completed jobs are never casually reopened (no out-edges except DISPUTED).
class JobMachine {
  static const actorMatrix = <String, Map<String, List<String>>>{
    AppRoles.technician: {
      JobStatus.requested: [JobStatus.accepted],
      JobStatus.accepted: [JobStatus.enRoute, JobStatus.cancelled],
      JobStatus.scheduled: [JobStatus.enRoute, JobStatus.cancelled],
      JobStatus.enRoute: [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.arrived: [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.inProgress: [JobStatus.completed, JobStatus.disputed],
      JobStatus.completed: [JobStatus.disputed],
    },
    AppRoles.customer: {
      JobStatus.requested: [JobStatus.cancelled],
      JobStatus.accepted: [JobStatus.cancelled],
      JobStatus.scheduled: [JobStatus.cancelled],
      JobStatus.enRoute: [JobStatus.cancelled],
      JobStatus.arrived: [JobStatus.cancelled],
      JobStatus.inProgress: [JobStatus.disputed],
      JobStatus.completed: [JobStatus.disputed],
    },
    AppRoles.admin: {
      JobStatus.requested: [JobStatus.accepted, JobStatus.cancelled],
      JobStatus.accepted: [JobStatus.enRoute, JobStatus.cancelled],
      JobStatus.scheduled: [JobStatus.enRoute, JobStatus.cancelled],
      JobStatus.enRoute: [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.arrived: [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.inProgress: [JobStatus.completed, JobStatus.disputed],
      JobStatus.completed: [JobStatus.disputed],
    },
  };

  static bool canActor(
      {required String role,
      required String from,
      required String to}) {
    if (!JobStatus.canTransition(from, to)) return false;
    final allowed = actorMatrix[role]?[from] ?? const [];
    return allowed.contains(to);
  }

  static List<String> nextFor(String role, String from) =>
      List.of(actorMatrix[role]?[from] ??
          const <String>[]);

  static bool requiresReason(String to) =>
      to == JobStatus.cancelled || to == JobStatus.disputed;

  static bool isTerminal(String s) =>
      s == JobStatus.cancelled || s == JobStatus.disputed;

  static String? validateReason(String to, String? reason) {
    if (!requiresReason(to)) return null;
    if (reason == null || reason.trim().length < 5) {
      return to == JobStatus.cancelled
          ? 'Cancellation reason required (min 5 chars)'
          : 'Dispute reason required (min 5 chars)';
    }
    return null;
  }
}

/// Local status-history entry (mirrors job_status_history table).
class StatusEvent {
  final String from;
  final String to;
  final String actor;
  final DateTime at;
  final String? reason;
  const StatusEvent(
      {required this.from,
      required this.to,
      required this.actor,
      required this.at,
      this.reason});
}
