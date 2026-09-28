# Payments, commission, wallet

Flow: customer initiates (PENDING row, caller idempotency key — retries
return the same row) → provider payload → provider webhook → gateway
`verify()` against the provider API → `settle()` once (guarded; replays
return the stored row). Client success flags are ignored.

`settle()`: commission from `platform_settings.commission_percent`
(server-side), `technician_amount` computed, two ledger rows (earning +,
commission −), `PaymentSuccessful` event. Refunds: admin-only, SUCCEEDED
only, reason required, ledger reversal. Gateways (`PaymentGateway`
interface; `EsewaGateway`, `KhaltiGateway`) read creds from
`config/payments.php`; missing creds → clear 503, never fake success.

Wallet: no stored balance — `SUM(wallet_transactions)`. Withdrawals:
request (balance-checked, no movement) → admin paid/rejected (ledger moves
only on paid, with reference). Double decisions 409.
