import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'preview/preview_page.dart';
import 'share/share_receiver.dart';
import 'theme/shelf_theme.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Archivo', 'IBMPlexSans']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  runApp(ShelfApp(links: sharedLinks()));
}

class ShelfApp extends StatelessWidget {
  const ShelfApp({super.key, required this.links});

  final Stream<Uri> links;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'shelf',
      theme: shelfTheme(Brightness.light),
      darkTheme: shelfTheme(Brightness.dark),
      home: PreviewPage(links: links),
    );
  }
}
