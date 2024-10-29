import 'package:flutter/material.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class PostSearchPage extends StatefulWidget {
  const PostSearchPage({super.key});

  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  bool _hasTextContent = false;

  static final _tags = TagTranslationsService.knowTags;

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            scrollController: _textScrollController,
            onChanged: (text) {
              if (text.isEmpty == _hasTextContent) {
                setState(() {
                  _hasTextContent = text.isNotEmpty;
                });
              }
            },
            onSubmitted: (value) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostListPage(tags: value.trim().split(' '))));
            },
            decoration: InputDecoration(
              filled: true,
              hintText: i18n.postSearch.title,
              prefixIcon: Icon(Icons.search, color: Theme.of(context).inputDecorationTheme.hintStyle?.color),
              suffixIcon: _hasTextContent
                  ? IconButton(
                      icon: Icon(Icons.cancel, color: Theme.of(context).inputDecorationTheme.hintStyle?.color),
                      onPressed: () {
                        _textController.clear();
                        setState(() {
                          _hasTextContent = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
        ),
        if (_hasTextContent) IconButton(onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostListPage(tags: _textController.text.trim().split(' '))));
        }, icon: const Icon(Icons.search))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (context, horizontal) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildSearchField(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    runSpacing: 6,
                    spacing: 6,
                    children: [
                      for (final tag in _tags)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final text = _textController.text;
                            if (!text.split(' ').contains(tag)) {
                              _textController.text = '${text.trim()} $tag';
                              if (!_hasTextContent) {
                                setState(() {
                                  _hasTextContent = true;
                                });
                              }
                              _textController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _textController.text.length),
                              );
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (_textScrollController.hasClients) {
                                  _textScrollController.jumpTo(_textScrollController.position.maxScrollExtent);
                                }
                              });
                            }
                          },
                          child: TranslatedTag(
                            text: tag,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
