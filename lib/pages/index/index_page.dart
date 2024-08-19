import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/about/about_page.dart';
import 'package:yande_gui/pages/downloader/downloader_page.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/pages/post_search/post_search_page.dart';
import 'package:yande_gui/pages/settings/settings_page.dart';
import 'package:yande_gui/services/dns_service.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';
import 'package:yande_gui/widgets/lazy_indexed_stack/lazy_indexed_stack.dart';

class IndexPage extends StatefulWidget {
  final int? language;

  const IndexPage({super.key, required this.language});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  Map<(IconData, String), WidgetBuilder> get _pages => {
        (Icons.list_alt_outlined, i18n.postList.short): (context) => const PostListPage(),
        (Icons.search_outlined, i18n.postSearch.title): (context) => const PostSearchPage(),
        (Icons.cloud_download_outlined, i18n.downloader.title): (context) => const DownloaderPage(),
        (Icons.info_outlined, i18n.about.title): (context) => const AboutPage(),
        (Icons.settings, i18n.settings.title): (context) => const SettingsPage(),
      };

  final controller = PageController();

  int _selectedIndex = 0;

  bool _initialized = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      YandeClient instance;
      try {
        final List<String>? dns = await DnsService.fetchDns();

        final ips = dns != null ? StringArray3(dns) : null;
        instance = await YandeClient.newInstance(ips: ips);
      } catch (e) {
        instance = await YandeClient.newInstance(ips: null);
      }

      setYandeClient(instance);

      setState(() {
        _initialized = true;
      });

      UpdaterService.checkForUpdate().then((result) {
        if (result != null) {
          EasyLoading.showToast(
            i18n.update.newVersionFound(result.$1),
            toastPosition: EasyLoadingToastPosition.bottom,
            duration: const Duration(seconds: 6),
          );
        }
      }).catchError((e) {
        EasyLoading.showToast(i18n.update.checkUpdateFailed);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

    return Scaffold(
      body: switch (_initialized) {
        false => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching DNS...'),
              ],
            ),
          ),
        true => Row(
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
      },
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

  @override
  void didUpdateWidget(covariant IndexPage oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }
}
