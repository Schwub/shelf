import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../shelf/entry_page.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';

/// Takes or picks a photo, scaled to the cover size; null when cancelled.
typedef PickPhoto = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 500,
    maxHeight: 500,
    imageQuality: 85,
  );
  return file?.readAsBytes();
}

/// For albums MusicBrainz doesn't have: title, artist, year and a photo,
/// then the album entry to add it. Pops with [EntryResult.added].
class ManualAlbumPage extends StatefulWidget {
  const ManualAlbumPage({
    super.key,
    required this.shelf,
    this.groups = const [],
    this.title = '',
    this.artist = '',
    this.year,
    this.photo,
    this.pick = pickPhoto,
  });

  final ShelfRepository shelf;
  final List<TagGroup> groups;

  /// Prefilled from the search, or from a shared link's page.
  final String title, artist;
  final int? year;
  final Uint8List? photo;
  final PickPhoto pick;

  @override
  State<ManualAlbumPage> createState() => _ManualAlbumPageState();
}

class _ManualAlbumPageState extends State<ManualAlbumPage> {
  late final _title = TextEditingController(text: widget.title);
  late final _artist = TextEditingController(text: widget.artist);
  late final _year = TextEditingController(text: widget.year?.toString());
  late Uint8List? _photo = widget.photo;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final photo = await widget.pick(source);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _continue() async {
    final title = _title.text.trim(), artist = _artist.text.trim();
    final yearText = _year.text.trim();
    final year = int.tryParse(yearText);
    final error = title.isEmpty || artist.isEmpty
        ? 'Enter the title and the artist.'
        : yearText.isNotEmpty && (year == null || year < 1000 || year > 2100)
        ? 'Enter the year as four digits, like 1994.'
        : null;
    setState(() => _error = error);
    if (error != null) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => EntryPage.manual(
          manual: ManualAlbum(
            title: title,
            artist: artist,
            year: year,
            cover: _photo,
          ),
          shelf: widget.shelf,
          groups: widget.groups,
        ),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final label = text.labelSmall!.copyWith(color: c.muted);
    Widget field(String name, Widget input) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: label),
          const SizedBox(height: 8),
          input,
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                ShelfKey(
                  semanticLabel: 'Back',
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text('Add it yourself', style: text.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'For albums the search doesn’t know. Only you see them.',
              style: text.bodyMedium!.copyWith(color: c.muted),
            ),
            const SizedBox(height: 24),
            field('Title', ShelfField(controller: _title, hintText: 'Title')),
            field(
              'Artist',
              ShelfField(controller: _artist, hintText: 'Artist'),
            ),
            field(
              'Year (optional)',
              ShelfField(
                controller: _year,
                hintText: 'Year',
                keyboardType: TextInputType.number,
              ),
            ),
            Text('Cover (optional)', style: label),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox.square(
                    dimension: 96,
                    child: _photo == null
                        ? ColoredBox(color: c.surface)
                        : Image.memory(
                            _photo!,
                            fit: BoxFit.cover,
                            semanticLabel: 'Cover photo',
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Browsers can't open the camera from here.
                      if (!kIsWeb)
                        ShelfKey(
                          onPressed: () => _pick(ImageSource.camera),
                          child: const Text('Take photo'),
                        ),
                      ShelfKey(
                        onPressed: () => _pick(ImageSource.gallery),
                        child: const Text('Choose photo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              HelpLine(_error!, error: true),
              const SizedBox(height: 12),
            ],
            ShelfKey(
              primary: true,
              onPressed: _continue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
