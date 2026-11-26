import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth.dart';
import 'auth/auth_gate.dart';
import 'errors.dart';
import 'feed/feed_page.dart';
import 'friends/friends_page.dart';
import 'friends/friends_repository.dart';
import 'friends/name_gate.dart';
import 'friends/supabase_friends_repository.dart';
import 'home/home_page.dart';
import 'search/album_search.dart';
import 'search/musicbrainz.dart';
import 'settings/settings.dart';
import 'settings/supabase_settings_repository.dart';
import 'share/link_resolver.dart';
import 'share/share_receiver.dart';
import 'share/shared_link_inbox.dart';
import 'shelf/shelf_repository.dart';
import 'shelf/supabase_shelf_repository.dart';
import 'shelf/shelf_page.dart';
import 'theme/shelf_theme.dart';
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

/// Error reporting (Sentry); without a DSN nothing is sent.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _environment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'development',
);

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
  await runReporting(
    dsn: _sentryDsn,
    environment: _environment,
    app: () async {
      final supabase = await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseKey,
      );
      supabase.client.auth.onAuthStateChange.listen(
        (change) => reportAs(change.session?.user.id),
      );
      final client = reportingClient(http.Client());
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
          friends: SupabaseFriendsRepository(supabase.client),
          inbox: inbox,
          settings: await Settings.load(
            SupabaseSettingsRepository(supabase.client),
          ),
        ),
      );
    },
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
    required this.settings,
    required this.friends,
  });

  final Auth auth;
  final ShelfRepository shelf;
  final AlbumSearch search;
  final LinkResolver links;
  final SharedLinkInbox inbox;
  final Settings settings;
  final FriendsRepository friends;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settings.theme,
      builder: (context, chosen, home) => MaterialApp(
        title: 'shelf',
        theme: shelfTheme(chosen.colors),
        home: home,
      ),
      child: AuthGate(
        auth: auth,
        signedIn: NameGate(
          friends: friends,
          builder: (context, name) => HomePage(
            inbox: inbox,
            shelf: ShelfPage(
              auth: auth,
              shelf: shelf,
              search: search,
              links: links,
              inbox: inbox,
              settings: settings,
            ),
            feed: const FeedPage(),
            friends: FriendsPage(friends: friends, name: name),
          ),
        ),
      ),
    );
  }
}
