from pathlib import Path
import tempfile
import unittest
from fontTools.ttLib import TTFont
import generate

SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>'''

class GeneratorTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root/'clock.svg').write_text(SVG, encoding='utf-8')
        (self.root/'LICENSE').write_text('Copyright (c) Lucide Contributors\nISC License', encoding='utf-8')
        self.mapping = self.root/'map.csv'
        generate.write_map(self.mapping, [generate.Entry('clock', 0xE900, 'clock.svg', True)])

    def build(self, suffix):
        font, dart = self.root/(suffix+'.ttf'), self.root/(suffix+'.dart')
        generate.build(self.root, self.mapping, 'TestIcons', 'TestIcons', font, dart, self.root/'LICENSE')
        return font, dart

    def test_font_round_trip_holes_metrics_license_and_reproducibility(self):
        first, dart = self.build('first')
        second, second_dart = self.build('second')
        self.assertEqual(first.read_bytes(), second.read_bytes())
        self.assertEqual(dart.read_bytes(), second_dart.read_bytes())
        self.assertIn('matchTextDirection: true', dart.read_text())
        font = TTFont(first)
        self.assertEqual(font.getBestCmap(), {0xE900:'clock'})
        self.assertEqual(font['glyf']['clock'].numberOfContours, 3)
        self.assertEqual(font['hmtx']['clock'][0], generate.EM)
        self.assertEqual(font['hmtx']['clock'][1], font['glyf']['clock'].xMin)
        self.assertIn('Lucide Contributors', font['name'].getDebugName(0))
        self.assertIn('ISC License', font['name'].getDebugName(13))
        self.assertEqual(font['hhea'].ascent, generate.EM)
        self.assertEqual(font['hhea'].descent, 0)

    def test_generated_identifiers_cannot_collide(self):
        for name in ['all', 'names', 'class']:
            with self.assertRaises(ValueError):
                generate.write_map(self.mapping, [generate.Entry(name, 0xE900, 'clock.svg', False)])

    def test_retired_allocation_cannot_be_reused(self):
        previous = [generate.Entry('clock',0xE900,'clock.svg',True,'retired')]
        with self.assertRaises(ValueError):
            generate.check_history([generate.Entry('clock',0xE900,'clock.svg',True)],previous)
        with self.assertRaises(ValueError):
            generate.check_history([generate.Entry('other',0xE900,'clock.svg',False)],previous)

    def test_history_rejects_renumbering_and_allows_append(self):
        previous = generate.read_map(self.mapping)
        with self.assertRaises(ValueError):
            generate.check_history([generate.Entry('clock',0xE901,'clock.svg',True)],previous)
        generate.check_history(previous+[generate.Entry('clock-two',0xE901,'clock.svg',False)],previous)

    def test_duplicate_codepoint_including_tombstone_is_rejected(self):
        with self.mapping.open('a',encoding='utf-8') as target:
            target.write('retired,U+E900,clock.svg,false,retired\n')
        with self.assertRaises(ValueError):generate.read_map(self.mapping)

    def test_source_outside_directory_is_rejected(self):
        generate.write_map(self.mapping,[generate.Entry('clock',0xE900,'../clock.svg',False)])
        with self.assertRaises(ValueError):self.build('unsafe')

    def test_wrong_stroke_and_empty_outline_are_rejected(self):
        source=self.root/'clock.svg'
        source.write_text(SVG.replace('1.75','2'),encoding='utf-8')
        with self.assertRaises(ValueError):self.build('wrong')
        source.write_text(SVG[:SVG.index('<circle')]+ '</svg>',encoding='utf-8')
        with self.assertRaises(ValueError):self.build('empty')

if __name__ == '__main__':unittest.main()
