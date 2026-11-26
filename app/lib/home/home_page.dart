import 'package:material_ui/material_ui.dart';

/// The three tabs (Shelf, Feed, Friends) with a navigation bar. Each tab has
/// its own Navigator, so it keeps its screens while another tab is shown;
/// system back pops the current tab first.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.shelf,
    required this.feed,
    required this.friends,
  });

  final Widget shelf, feed, friends;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final _navigators = List.generate(3, (_) => GlobalKey<NavigatorState>());

  void _select(int tab) {
    if (tab == _tab) {
      // Tapping the current tab goes back to its first screen.
      _navigators[tab].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _tab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roots = [widget.shelf, widget.feed, widget.friends];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          for (final (i, root) in roots.indexed)
            NavigatorPopHandler<Object?>(
              enabled: i == _tab,
              onPopWithResult: (_) => _navigators[i].currentState?.maybePop(),
              child: TickerMode(
                enabled: i == _tab,
                child: Navigator(
                  key: _navigators[i],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => root,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Shelf',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Friends',
          ),
        ],
      ),
    );
  }
}
