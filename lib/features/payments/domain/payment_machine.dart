/// Payment state machine (§18). Server verifies authoritatively;
/// UI mirrors for honest status display. Never trust client success.
///
/// States: PENDING → PROCESSING → SUCCEEDED | FAILED
/// FAILED → PENDING (customer retry, same idempotency scope is server-side)
/// SUCCEEDED → REFUNDED (admin/support only, with reason)
class PaymentMachine {
  static const pending = 'PENDING';
  static const processing = 'PROCESSING';
  static const succeeded = 'SUCCEEDED';
  static const failed = 'FAILED';
  static const refunded = 'REFUNDED';

  static const transitions = <String, List<String>>{
    pending: [processing, succeeded, failed],
    processing: [succeeded, failed],
    succeeded: [refunded],
    failed: [pending],
    refunded: [],
  };

  static bool canTransition(String from, String to) =>
      transitions[from]?.contains(to) ?? false;

  static bool get canRetry => true; // FAILED → PENDING always allowed
  static bool canRefund(String from) => from == succeeded;

  /// Client-side amount guard. Server revalidates authoritatively.
  /// Returns error string or null if ok.
  static String? validateAmount(double amount, {String currency = 'USD'}) {
    if (amount.isNaN || amount <= 0) return 'Amount must be positive';
    if (amount > 100000) return 'Amount exceeds single-payment limit';
    if (currency.trim().isEmpty) return 'Currency required';
    return null;
  }

  static String? validateRefund(String status, String? reason) {
    if (status != succeeded) return 'Only succeeded payments can be refunded';
    if (reason == null || reason.trim().length < 5) {
      return 'Refund reason required (min 5 chars)';
    }
    return null;
  }
}
