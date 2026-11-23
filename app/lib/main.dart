import 'package:material_ui/material_ui.dart';

import 'share/share_receiver.dart';

void main() {
  runApp(ShelfApp(links: sharedLinks()));
}

/// Placeholder until M1: shows the last link shared into the app.
class ShelfApp extends StatelessWidget {
  const ShelfApp({super.key, required this.links});

  final Stream<Uri> links;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'shelf',
      home: Scaffold(
        appBar: AppBar(title: const Text('shelf')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<Uri>(
              stream: links,
              builder: (context, snapshot) => Text(
                snapshot.data?.toString() ??
                    'Share an album from Spotify or Bandcamp to add it.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
