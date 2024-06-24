import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yande_gui/pages/about/about_page.dart';
import 'package:yande_gui/pages/downloader/downloader_page.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/widgets/lazy_indexed_stack/lazy_indexed_stack.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final Map<(IconData, String), WidgetBuilder> _pages = {
    (Icons.list_alt_outlined, 'Post'): (context) => const PostListPage(),
    (Icons.cloud_download_outlined, 'Downloader'): (context) => const DownloaderPage(),
    (Icons.info_outlined, 'About'): (context) => const AboutPage(),
    (Icons.settings, 'Settings'): (context) => const Placeholder(),
  };

  final controller = PageController();

  int _selectedIndex = 0;

  @override
  void initState() {
    UpdaterService.checkForUpdate().then((result) {
      if (result != null) {
        EasyLoading.showToast(
          'New version found: ${result.$1}.\nPlease go to the About page and click Download Update.',
          toastPosition: EasyLoadingToastPosition.bottom,
          duration: const Duration(seconds: 6),
        );
      }
    }).catchError((e) {
      EasyLoading.showToast('Check for update failed. Please check your Internet connection.');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

    return Scaffold(
      body: Row(
        children: [
          if (!isVertical)
            NavigationRail(
              destinations: [
                for (final key in _pages.keys)
                  NavigationRailDestination(
                    icon: Icon(key.$1),
                    label: Text(key.$2),
                  ),
              ],
              labelType: NavigationRailLabelType.all,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(
            child: LazyIndexedStack(
              index: _selectedIndex,
              children: [
                for (final page in _pages.values) page(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: switch (isVertical) {
        true => BottomNavigationBar(
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            items: [
              for (final key in _pages.keys)
                BottomNavigationBarItem(
                  icon: Icon(key.$1),
                  label: key.$2,
                ),
            ],
          ),
        false => null,
      },
    );
  }
}
