# Backend architecture

Thin controllers → FormRequests (validate) → Policies/Gates (authorize) →
Services/Actions (business logic, transactions) → Eloquent models → MySQL.
Cross-cutting changes publish Events → Listeners (notifications) and
broadcast on private channels (Reverb; `log` driver locally).

```
app/Models, app/Enums
app/Http/{Controllers/Api/V1, Requests/ApiRequests, Resources/ApiResources, Middleware/EnsureRole}
app/Services/{Matching,Location,Verification,Jobs(Accept+Lifecycle),Notifications,Payments/*}
app/Policies/MarketplacePolicy (+ Gate definitions in AppServiceProvider)
app/Events, app/Listeners/NotifyJobParties, app/Jobs (scheduler/queue), app/Notifications (n/a — see services)
routes/api.php (v1), bootstrap/app.php (envelope errors, role alias)
```

Business rules live in Services + Enums, never in controllers or Flutter.
Financial and assignment flows always run inside DB transactions with row
locks (`lockForUpdate`). See `SECURITY.md` (repo root `backend/` folder is
the old contract stub; this `backend-app` is the implementation).
