import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  test('English counts agree with their nouns', () {
    final d = t.downloads;
    expect(d.failedTasks(n: 1, count: '1'), '1 download failed');
    expect(d.failedTasks(n: 2, count: '2'), '2 downloads failed');
    expect(d.cancelledTasks(n: 1, count: '1'), '1 download cancelled');
    expect(d.activeTasks(n: 1, count: '1'), 'Downloading 1 item');
    expect(d.partialFailed(n: 1, count: '1'), '1 action failed');
    expect(t.postDetail.childCount(n: 1, count: '1'), '1 child');
    expect(t.postDetail.childCount(n: 3, count: '3'), '3 children');
    // The shown number keeps its grouping; the plural follows the value.
    expect(
      d.failedTasks(n: 1200, count: '1,200'),
      '1,200 downloads failed',
    );
  });

  test('Chinese counts use their one form', () {
    LocaleSettings.setLocaleSync(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    expect(t.downloads.failedTasks(n: 1, count: '1'), '1 项下载失败');
    expect(t.downloads.failedTasks(n: 2, count: '2'), '2 项下载失败');
  });
}
