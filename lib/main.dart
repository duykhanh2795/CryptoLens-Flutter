import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/cryptolens_app.dart';
import 'core/services/alert_realtime_service.dart';
import 'core/services/crypto_auth_service.dart';
import 'core/services/firebase_messaging_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: CryptoAuthService.supabaseUrl,
    anonKey: CryptoAuthService.supabaseAnonKey,
  );
  await CryptoFirebaseMessagingService.initialize();
  await AlertRealtimeService.initialize();
  runApp(const CryptoLensApp());
}
