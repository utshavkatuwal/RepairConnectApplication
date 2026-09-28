import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'core/config/env.dart';
import 'core/network/dio_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env optional; AppEnv falls back to localhost + fake backend.
  }
  Env.apiBaseUrl = AppEnv.apiBaseUrl;
  runApp(const ProviderScope(child: RepairConnectApp()));
}
