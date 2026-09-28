# RepairConnect backend (Laravel REST) — scaffold contract.
# Full Laravel app lives here in prod; this repo ships contract + schema
# because PHP/MySQL are not in this build env. Flutter never talks to MySQL.

Versioned base: /api/v1

Auth:
POST /api/v1/auth/register {name,email,password,role} -> {token,user}
POST /api/v1/auth/login {email,password} -> {token,user}
POST /api/v1/auth/logout (auth)
POST /api/v1/auth/refresh {refresh_token} -> {token}

Envelope success: {success:true,data:{...},message?,meta?}
Envelope error: {success:false,message,code?,errors?}

Authorization (server-enforced, never trust client role):
- CUSTOMER: own requests/bookings/chat/payments/reviews.
- TECHNICIAN: verified only for accept; own jobs only.
- ADMIN: /api/v1/admin/* + audit_logs write.

Key rules:
- Job transitions validated server-side via transitions map (see AppRoles/JobStatus).
- Reviews only after COMPLETED booking by participant.
- Payments: create with idempotency_key; verify provider webhook before SUCCEEDED.
- Uploads: mime/size validated, safe filenames, private disk for verification docs.
- Rate limit auth + payment endpoints; CORS allowlisted; SQL via Eloquent bindings.

Laravel scaffold to create in prod:
- composer create-project laravel/laravel backend
- Models: User, TechnicianProfile, Category, ServiceItem, ServiceRequest, Booking, Conversation, Message, Notification, Payment, Review, Complaint, AuditLog
- Controllers: AuthController, CatalogController, TechnicianController, RequestController, BookingController (transition), ChatController, NotificationController, PaymentController (webhook), ReviewController, AdminController
- Middleware: auth:sanctum, role:CUSTOMER|TECHNICIAN|ADMIN, verified-technician
- routes/api.php versioned as above; Sanctum tokens; audit middleware on admin writes.
