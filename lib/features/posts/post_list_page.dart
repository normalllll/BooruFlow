import 'package:flutter/material.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';

class PostListPage extends StatelessWidget {
  const PostListPage({super.key, required this.tags, required this.sourceId});
  final List<String> tags;
  final String sourceId;
  @override
  Widget build(BuildContext context) =>
      DiscoveryPage(tags: tags, sourceId: sourceId);
}
