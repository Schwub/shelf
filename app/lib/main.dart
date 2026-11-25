import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth.dart';
import 'auth/auth_gate.dart';
import 'search/album_search.dart';
import 'search/musicbrainz.dart';
import 'share/link_resolver.dart';
import 'share/share_receiver.dart';
import 'share/shared_link_inbox.dart';
import 'shelf/shelf_data.dart';
import 'shelf/shelf_page.dart';
import 'theme/shelf_theme.dart';
import 'theme/theme_choice.dart';
import 'tracks/track_source.dart';

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

/// The contact MusicBrainz asks every client to send (repository variable).
const _musicBrainzContact = String.fromEnvironment('MUSICBRAINZ_CONTACT');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Archivo', 'IBMPlexSans']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  // Before anything slow, so the link that launches the app isn't missed.
  final inbox = SharedLinkInbox(sharedLinks());
  final supabase = await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
  );
  final client = http.Client();
  final musicBrainz = MusicBrainz(client, contact: _musicBrainzContact);
  runApp(
    ShelfApp(
      auth: SupabaseAuth(supabase.client.auth),
      shelf: SupabaseShelfRepository(
        supabase.client,
        MusicBrainzTracks(musicBrainz),
      ),
      search: MusicBrainzSearch(musicBrainz),
      links: SupabaseLinkResolver(supabase.client, client),
      inbox: inbox,
      theme: await ThemeChoice.load(),
    ),
  );
}

class ShelfApp extends StatelessWidget {
  const ShelfApp({
    super.key,
    required this.auth,
    required this.shelf,
    required this.search,
    required this.links,
    required this.inbox,
    required this.theme,
  });

  final Auth auth;
  final ShelfRepository shelf;
  final AlbumSearch search;
  final LinkResolver links;
  final SharedLinkInbox inbox;
  final ThemeChoice theme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: theme,
      builder: (context, chosen, home) => MaterialApp(
        title: 'shelf',
        theme: shelfTheme(chosen.colors),
        home: home,
      ),
      child: AuthGate(
        auth: auth,
        signedIn: ShelfPage(
          auth: auth,
          shelf: shelf,
          search: search,
          links: links,
          inbox: inbox,
          theme: theme,
        ),
      ),
    );
  }
}
