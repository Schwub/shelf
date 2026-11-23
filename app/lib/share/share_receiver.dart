import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'shared_link.dart';

/// Links shared into the app from the system share sheet: first the one that
/// launched the app (if any), then those shared while it runs.
Stream<Uri> sharedLinks() async* {
  // The plugin has no web implementation.
  if (kIsWeb) return;
  final sharing = ReceiveSharingIntent.instance;
  yield* Stream.fromIterable(_links(await sharing.getInitialMedia()));
  // Otherwise a hot restart or engine re-attach delivers the launch link again.
  await sharing.reset();
  await for (final media in sharing.getMediaStream()) {
    yield* Stream.fromIterable(_links(media));
  }
}

Iterable<Uri> _links(List<SharedMediaFile> media) => media
    .where(
      (m) => m.type == SharedMediaType.text || m.type == SharedMediaType.url,
    )
    .map((m) => extractSharedUrl(m.path))
    .nonNulls;
