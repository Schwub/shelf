import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth.dart';
import 'auth/auth_gate.dart';
import 'shelf/shelf_data.dart';
import 'shelf/shelf_page.dart';
import 'theme/shelf_theme.dart';

// Defaults: the local Supabase (`supabase start`). Builds for the hosted
// project pass both with --dart-define.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);
const _supabaseKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
);

Future<void> main() async {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Archivo', 'IBMPlexSans']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  final supabase = await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
  );
  runApp(
    ShelfApp(
      auth: SupabaseAuth(supabase.client.auth),
      shelf: SupabaseShelfRepository(supabase.client),
    ),
  );
}

class ShelfApp extends StatelessWidget {
  const ShelfApp({super.key, required this.auth, required this.shelf});

  final Auth auth;
  final ShelfRepository shelf;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'shelf',
      theme: shelfTheme(Brightness.light),
      darkTheme: shelfTheme(Brightness.dark),
      home: AuthGate(
        auth: auth,
        signedIn: ShelfPage(auth: auth, shelf: shelf),
      ),
    );
  }
}
