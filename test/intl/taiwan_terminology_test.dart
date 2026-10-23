import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Taiwan copy excludes mainland terminology in values', () {
    const forbidden = [
      '視頻',
      '文件夾',
      '文件',
      '網絡',
      '設置',
      '默認',
      '緩存',
      '信息',
      '鏈接',
      '用戶',
      '賬號',
      '登錄',
      '搜索',
      '支持',
      '刷新',
      '加載',
      '菜單',
      '窗口',
      '屏幕',
      '全屏',
      '自定義',
      '保存',
      '批量',
      '隊列',
      '縮略圖',
      '端口',
      '服務器',
      '程序',
      '軟件',
      '數據',
      '訪問',
      '分辨率',
      '質量',
      '開源許可',
      '日誌',
      '點擊',
      '存儲',
      '設備',
    ];
    final issues = <String>[];
    final lines = File('lib/intl/zh_TW.i18n.yaml').readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = RegExp(
        r'^\s*([A-Za-z0-9_]+):\s+(.+)$',
      ).firstMatch(lines[i]);
      if (match == null) continue;
      final value = match[2]!.replaceAll('應用程式', '');
      if (value.contains('應用')) {
        issues.add('${i + 1}: application verb must be 套用');
      }
      for (final word in forbidden) {
        if (value.contains(word)) {
          issues.add('${i + 1}: ${match[1]} contains $word');
        }
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}
