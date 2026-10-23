import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keep redistributed font licenses available in the app's license page.
void registerAppLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Noto Sans SC',
      'Noto Sans JP',
    ], await rootBundle.loadString('assets/fonts/OFL-NotoSansCJK.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Lucide Icons',
      'BooruFlowIcons',
    ], await rootBundle.loadString('assets/fonts/LICENSE-Lucide.txt'));
  });
}
