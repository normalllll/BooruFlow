// Diagnostic only: production main never imports the icon overview.
import 'package:booruflow/app/icons.g.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

class IconGallery extends StatefulWidget {
  const IconGallery({super.key});
  @override
  State<IconGallery> createState() => _IconGalleryState();
}

class _IconGalleryState extends State<IconGallery> {
  bool _rtl = false;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
    child: ColoredBox(
      color: FrostThemeTokens.of(context).surface,
      child: SafeArea(
        child: SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostButton(
                label: _rtl ? 'RTL' : 'LTR',
                variant: FrostButtonVariant.plain,
                onPressed: () => setState(() => _rtl = !_rtl),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < BooruFlowIcons.all.length; i++)
                    SizedBox(
                      width: 80,
                      height: 44,
                      child: Column(
                        children: [
                          FrostIcon(
                            FrostIconData.glyph(BooruFlowIcons.all[i]),
                            size: 20,
                            color: FrostThemeTokens.of(context).textPrimary,
                            semanticLabel: BooruFlowIcons.names[i],
                          ),
                          Text(
                            BooruFlowIcons.names[i],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              inherit: false,
                              decoration: TextDecoration.none,
                              fontSize: 8,
                              color: FrostThemeTokens.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
