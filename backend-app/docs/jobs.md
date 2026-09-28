# Jobs lifecycle

Request: customer creates → `requested` (never auto-assigned, §14).
Matching (`MatchingService`): active + approved + specialty + online +
within `service_radius` (haversine on real coordinates), nearest first.
Accept (`AcceptJobService`): verifies all eligibility, `lockForUpdate`s the
request, 409s if taken, creates job + conversation + participants, marks
tech busy — one transaction. Second accepter gets 409, never a duplicate.

Transitions (`JobLifecycleService` + `JobStatus::transitions`): tech moves
forward, customer may cancel pre-completion or dispute, admin all valid
moves. Cancel/dispute require reason. Completed reopens only via dispute.
Every move fires `JobStatusChanged` (notify + broadcast). Scheduler expires
72h-stale requests; cleanup prunes old read notifications.
