import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/models.dart';

/// Technician wallet: balance derived server-side from the ledger.
/// The client never computes or stores money.
class WalletRepository {
  final DioClient api;
  WalletRepository(this.api);

  Future<double> balance() async {
    try {
      final r = await api.getRetry('/api/v1/wallet');
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      if (data is Map) {
        return double.tryParse('${data['balance'] ?? 0}') ?? 0;
      }
      return 0;
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<List<Transaction>> ledger() async {
    try {
      final r = await api.getRetry('/api/v1/wallet/ledger');
      final body = Map<String, dynamic>.from(r.data as Map);
      final items = body['data'];
      if (items is! List) return [];
      return items
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return Transaction(
              id: '${m['id']}',
              paymentId: '${m['reference_id'] ?? m['id']}',
              kind: '${m['type'] ?? ''}'.toUpperCase(),
              amount: double.tryParse('${m['amount'] ?? 0}') ?? 0,
            );
          })
          .toList();
    } catch (e) {
      throw api.mapError(e);
    }
  }

  Future<Map<String, dynamic>> withdraw(
      {required double amount,
      required String method,
      required String account}) async {
    try {
      final r = await api.dio.post('/api/v1/withdrawals', data: {
        'amount': amount,
        'method': method,
        'account_identifier': account,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw api.mapError(e);
    }
  }
}
