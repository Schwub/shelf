import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/widgets/album_stage.dart';

import 'harness.dart';

void main() {
  const album = Album(id: 'a', title: 'Kid A', artist: 'Radiohead');

  testWidgets('a cover is blurred behind itself', (tester) async {
    await tester.pumpWidget(
      themed(
        const AlbumStage(
          Album(
            id: 'a',
            title: 'Kid A',
            artist: 'Radiohead',
            coverUrl: 'https://example.com/kid-a.jpg',
          ),
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('a photo of an album added by hand is blurred too', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(AlbumStage(album, photo: Uint8List.fromList([0x89, 0x50]))),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('without a cover the stage stays plain', (tester) async {
    await tester.pumpWidget(themed(const AlbumStage(album)));

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.bySemanticsLabel('Cover of Kid A'), findsOneWidget);
  });
}
