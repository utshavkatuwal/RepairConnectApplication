import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secrets -> secure storage. Non-sensitive prefs -> SharedPreferences.
class SessionStore {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static const _kToken = 'rc_token';
  static const _kRefresh = 'rc_refresh';
  static const _kRole = 'rc_role';
  static const _kUserId = 'rc_user_id';
  static const _kName = 'rc_name';
  static const _kEmail = 'rc_email';
  static const _kVerified = 'rc_verified';
  static const _kTechVerified = 'rc_tech_verified';
  static const _kTechStatus = 'rc_tech_status';

  Future<void> saveSession(
      {required String token,
      String? refresh,
      required String role,
      required String userId,
      String? name,
      String? email,
      bool isVerified = true,
      bool techVerified = false,
      String techStatus = 'PENDING'}) async {
    await _secure.write(key: _kToken, value: token);
    if (refresh != null) await _secure.write(key: _kRefresh, value: refresh);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRole, role);
    await p.setString(_kUserId, userId);
    if (name != null) await p.setString(_kName, name);
    if (email != null) await p.setString(_kEmail, email);
    await p.setBool(_kVerified, isVerified);
    await p.setBool(_kTechVerified, techVerified);
    await p.setString(_kTechStatus, techStatus);
  }

  Future<String?> readToken() => _secure.read(key: _kToken);
  Future<String?> readRefreshToken() => _secure.read(key: _kRefresh);
  Future<String?> readRole() async =>
      (await SharedPreferences.getInstance()).getString(_kRole);
  Future<String?> readUserId() async =>
      (await SharedPreferences.getInstance()).getString(_kUserId);
  Future<String?> readName() async =>
      (await SharedPreferences.getInstance()).getString(_kName);
  Future<String?> readEmail() async =>
      (await SharedPreferences.getInstance()).getString(_kEmail);
  Future<bool> readVerified() async =>
      (await SharedPreferences.getInstance()).getBool(_kVerified) ?? true;
  Future<bool> readTechVerified() async =>
      (await SharedPreferences.getInstance()).getBool(_kTechVerified) ?? false;
  Future<String> readTechStatus() async =>
      (await SharedPreferences.getInstance()).getString(_kTechStatus) ??
      'PENDING';

  Future<void> saveToken(String t) => _secure.write(key: _kToken, value: t);

  Future<void> clear() async {
    await _secure.deleteAll();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRole);
    await p.remove(_kUserId);
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kVerified);
    await p.remove(_kTechVerified);
    await p.remove(_kTechStatus);
  }
}
