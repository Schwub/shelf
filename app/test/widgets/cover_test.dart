import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/widgets/cover.dart';

import 'harness.dart';

void main() {
  const demo = Album(id: 'a', title: 'Demo', artist: 'Anna');

  testWidgets('an album without a cover gets made-up art', (tester) async {
    await tester.pumpWidget(themed(const Cover(demo)));

    expect(find.byType(CoverArt), findsOneWidget);
    expect(find.bySemanticsLabel('Cover of Demo'), findsOneWidget);
  });

  test('the art is always the same for an album, and varies between them', () {
    expect(
      CoverArt.of(demo),
      CoverArt.of(const Album(id: 'b', title: 'Demo', artist: 'Anna')),
      reason: 'by title and artist, not by ID',
    );
    final looks = {
      for (var i = 0; i < 40; i++)
        CoverArt.of(Album(id: '$i', title: 'Album $i', artist: 'Artist')),
    };
    expect(looks.length, greaterThan(10));
  });
}
