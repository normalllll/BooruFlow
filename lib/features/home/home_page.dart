import 'package:flutter/material.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';
import 'package:booruflow/features/discovery/logic.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.loader});
  final CollectionLoader? loader;
  @override
  Widget build(BuildContext context) => DiscoveryPage(loader: loader);
}
