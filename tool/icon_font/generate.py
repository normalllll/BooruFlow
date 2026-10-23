"""Build a monochrome Flutter icon font from an explicit, append-only source map."""
from __future__ import annotations
import argparse
import csv
from dataclasses import dataclass
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import pathops
from picosvg.svg import SVG
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path
from fontTools.ttLib import TTFont

EM = 1536  # Exact 64x scale of the source 24x24 canvas, never bounds-normalized.
SCALE = EM / 24
FIELDS = ['name', 'codepoint', 'file', 'rtl', 'status']

@dataclass(frozen=True)
class Entry:
    name: str
    codepoint: int
    file: str
    rtl: bool
    status: str = 'active'

    @property
    def symbol(self):
        parts = self.name.split('-')
        return parts[0] + ''.join(part.title() for part in parts[1:])

def read_map(file: Path) -> list[Entry]:
    with file.open(encoding='utf-8-sig', newline='') as source:
        reader = csv.DictReader(source)
        if reader.fieldnames != FIELDS:
            raise ValueError(f'Map header must be {FIELDS}')
        result = []
        for row in reader:
            if row['rtl'] not in ('true', 'false') or row['status'] not in ('active', 'retired'):
                raise ValueError(f'Invalid rtl/status: {row}')
            name = row['name']
            if not re.fullmatch(r'[a-z][a-z0-9]*(?:-[a-z0-9]+)*', name):
                raise ValueError(f'Invalid semantic name: {name}')
            codepoint = int(row['codepoint'].removeprefix('U+'), 16)
            if not 0xE000 <= codepoint <= 0xF8FF:
                raise ValueError(f'Not a BMP private-use codepoint: {name}')
            result.append(Entry(name, codepoint, row['file'], row['rtl'] == 'true', row['status']))
    validate_entries(result)
    return result

def validate_entries(entries: list[Entry]):
    for entry in entries:
        if not re.fullmatch(r'[a-z][a-z0-9]*(?:-[a-z0-9]+)*', entry.name):
            raise ValueError('Invalid semantic name')
        if not 0xE000 <= entry.codepoint <= 0xF8FF or entry.status not in ('active', 'retired'):
            raise ValueError('Invalid allocation/status')
        if entry.symbol in {'all', 'names', 'class', 'return', 'if', 'else', 'in', 'for', 'while', 'switch', 'case', 'default', 'break', 'continue', 'new', 'const', 'final', 'var', 'void', 'extends', 'implements', 'with', 'this', 'super', 'true', 'false', 'null', 'throw', 'try', 'catch', 'finally', 'assert', 'enum', 'is', 'as', 'rethrow', 'do'}:
            raise ValueError('Semantic name produces a Dart reserved identifier')
    for field in ('name', 'codepoint', 'symbol'):
        values = [getattr(entry, field) for entry in entries]
        if len(set(values)) != len(values):
            raise ValueError(f'Duplicate {field}, including retired entries')
    if [entry.codepoint for entry in entries] != sorted(entry.codepoint for entry in entries):
        raise ValueError('Map rows must remain in ascending allocation order')

def write_map(file: Path, entries: list[Entry]):
    validate_entries(entries)
    with file.open('w', encoding='utf-8', newline='') as target:
        writer = csv.writer(target, lineterminator='\n')
        writer.writerow(FIELDS)
        writer.writerows((e.name, f'U+{e.codepoint:04X}', e.file, str(e.rtl).lower(), e.status) for e in entries)

def check_history(entries: list[Entry], previous: list[Entry]):
    current = {entry.name: entry for entry in entries}
    for old in previous:
        new = current.get(old.name)
        if new is None or new.codepoint != old.codepoint:
            raise ValueError(f'Existing allocation removed or renumbered: {old.name}')
        if old.status == 'retired' and new.status != 'retired':
            raise ValueError(f'Retired allocation cannot be reused: {old.name}')
    maximum = max((entry.codepoint for entry in previous), default=0xDFFF)
    previous_names = {entry.name for entry in previous}
    if any(entry.codepoint <= maximum for entry in entries if entry.name not in previous_names):
        raise ValueError('New allocations must append after all existing/retired codepoints')

def source_outline(file: Path):
    source = file.read_text(encoding='utf-8-sig')
    root = ET.fromstring(source)
    expected = {'viewBox': '0 0 24 24', 'stroke-width': '1.75', 'stroke-linecap': 'round', 'stroke-linejoin': 'round'}
    for attribute, value in expected.items():
        if root.get(attribute) != value:
            raise ValueError(f'{file}: expected {attribute}={value}')
    pico = SVG.fromstring(source.replace('currentColor', '#000000')).topicosvg(ndigits=6)
    combined = pathops.Path()
    for shape in pico.shapes():
        if shape.fill not in ('black', '#000000', '#000', 'rgb(0, 0, 0)') or shape.opacity != 1 or shape.fill_opacity != 1:
            raise ValueError(f'{file}: font input must be opaque monochrome')
        parse_path(shape.as_path().d, combined.getPen())
    outline = pathops.simplify(combined, fix_winding=True, clockwise=False)
    # SvgPicture previously clipped overflow to its 24x24 viewBox. Preserve that
    # visible outline instead of shrinking all geometry to fit a stroke overshoot.
    viewport = pathops.Path()
    viewport.moveTo(0, 0)
    viewport.lineTo(24, 0)
    viewport.lineTo(24, 24)
    viewport.lineTo(0, 24)
    viewport.close()
    outline = pathops.op(outline, viewport, pathops.PathOp.INTERSECTION, fix_winding=True, clockwise=False)
    recording = RecordingPen()
    outline.draw(recording)
    if any(operation == 'endPath' for operation, _ in recording.value) or not recording.value:
        raise ValueError(f'{file}: empty or open expanded outline')
    return outline, sum(operation == 'closePath' for operation, _ in recording.value)

def tight_bounds(path):
    pen = BoundsPen(None)
    path.draw(pen)
    return pen.bounds

def svg_path(path):
    pen = SVGPathPen(None)
    path.draw(pen)
    return pen.getCommands()

def save_review(directory: Path, name: str, source: Path, outline, rebuilt):
    directory.mkdir(parents=True, exist_ok=True)
    (directory / f'{name}-source.svg').write_bytes(source.read_bytes())
    for label, path in [('expanded', outline), ('font', rebuilt)]:
        (directory / f'{name}-{label}.svg').write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="{svg_path(path)}"/></svg>', encoding='utf-8')
    # Independent source and reconstructed font overlays, for visual review.
    source_svg = source.read_text(encoding='utf-8-sig').replace('currentColor', '#ff0000')
    source_svg = re.sub(r'^<svg\b', '<svg opacity=".55"', source_svg.strip())
    (directory / f'{name}-overlay.svg').write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">' + source_svg +
        f'<path opacity=".55" fill="#00bfff" d="{svg_path(rebuilt)}"/></svg>', encoding='utf-8')

def build(source: Path, mapping: Path, family: str, class_name: str, font_file: Path, dart_file: Path,
          license_file: Path, review: Path | None = None, previous: Path | None = None):
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9 ]{0,62}', family) or not re.fullmatch(r'[A-Z][A-Za-z0-9]*', class_name):
        raise ValueError('Use a valid font family and PascalCase Dart class name')
    entries = read_map(mapping)
    if previous is not None:
        check_history(entries, read_map(previous))
    active = [entry for entry in entries if entry.status == 'active']
    if not active:
        raise ValueError('At least one active icon is required')
    glyphs = {'.notdef': TTGlyphPen(None).glyph()}
    outlines = {}
    source = source.resolve()
    for entry in active:
        file = (source / entry.file).resolve()
        if not file.is_relative_to(source) or file.suffix != '.svg':
            raise ValueError(f'Icon must be an SVG within the source directory: {entry.file}')
        outline, contours = source_outline(file)
        pen = TTGlyphPen(None)
        outline.draw(TransformPen(Cu2QuPen(pen, max_err=1 / 64), (SCALE, 0, 0, -SCALE, 0, EM)))
        glyph = pen.glyph()
        if glyph.numberOfContours != contours:
            raise ValueError(f'{entry.name}: contours lost in cubic-to-quadratic conversion')
        glyphs[entry.name] = glyph
        outlines[entry.name] = (outline, file)
    builder = FontBuilder(EM, isTTF=True)
    builder.setupGlyphOrder(list(glyphs))
    builder.setupCharacterMap({entry.codepoint: entry.name for entry in active})
    builder.setupGlyf(glyphs)
    # Keep each source origin: setting all side bearings to zero shifts inset icons.
    builder.setupHorizontalMetrics({name: (EM, getattr(glyph, 'xMin', 0)) for name, glyph in glyphs.items()})
    builder.setupHorizontalHeader(ascent=EM, descent=0, lineGap=0)
    license_text = license_file.read_text(encoding='utf-8-sig')
    copyright_text = '\n'.join(line for line in license_text.splitlines() if line.startswith('Copyright'))
    builder.setupNameTable({'familyName': family, 'styleName': 'Regular', 'uniqueFontIdentifier': family + '-1',
        'fullName': family, 'psName': family.replace(' ', ''), 'version': 'Version 1.000',
        'copyright': copyright_text, 'licenseDescription': license_text,
        'description': '24x24 monochrome icons; 1.75 source stroke; round caps and joins.'})
    builder.setupOS2(sTypoAscender=EM, sTypoDescender=0, sTypoLineGap=0, usWinAscent=EM, usWinDescent=0, fsSelection=0x40)
    builder.setupPost()
    builder.setupMaxp()
    builder.font['head'].created = builder.font['head'].modified = 3786912000
    builder.font.recalcTimestamp = False
    font_file.parent.mkdir(parents=True, exist_ok=True)
    builder.save(font_file)
    font = TTFont(font_file)
    if font.getBestCmap() != {entry.codepoint: entry.name for entry in active}:
        raise ValueError('Generated cmap does not match active allocations')
    dart = ['// GENERATED CODE - DO NOT MODIFY BY HAND.', '// Source: the app-owned stable icon codepoint map.',
            "import 'package:flutter/widgets.dart';", '', f'abstract final class {class_name} {{']
    for entry in active:
        glyph = font['glyf'][entry.name]
        rebuilt = pathops.Path()
        font.getGlyphSet()[entry.name].draw(TransformPen(rebuilt.getPen(), (1 / SCALE, 0, 0, -1 / SCALE, 0, 24)))
        rebuilt = pathops.simplify(rebuilt, fix_winding=True, clockwise=False)
        outline, file = outlines[entry.name]
        actual_bounds = tight_bounds(rebuilt)
        if min(actual_bounds) < -.02 or max(actual_bounds) > 24.02:
            raise ValueError(f'{entry.name}: visible glyph exceeds the original 24x24 canvas')
        # Vector-area and bounds checks catch wrong winding/filled holes without
        # raster pixel comparisons. Small quadratic/coordinate rounding is allowed.
        if abs(abs(rebuilt.area) - abs(outline.area)) > max(.02, abs(outline.area) * .01):
            raise ValueError(f'{entry.name}: filled area/holes changed')
        if any(abs(a - b) > .02 for a, b in zip(actual_bounds, tight_bounds(outline))):
            raise ValueError(f'{entry.name}: source bounds changed')
        if review is not None:
            save_review(review, entry.name, file, outline, rebuilt)
        rtl = ', matchTextDirection: true' if entry.rtl else ''
        dart.append(f"  static const {entry.symbol} = IconData(0x{entry.codepoint:X}, fontFamily: '{family}'{rtl});")
    dart += ['', '  static const all = <IconData>[', *(f'    {entry.symbol},' for entry in active), '  ];',
             '  static const names = <String>[', *(f"    '{entry.name}'," for entry in active), '  ];', '}']
    dart_file.parent.mkdir(parents=True, exist_ok=True)
    dart_file.write_text('\n'.join(dart) + '\n', encoding='utf-8')
    print(f'{len(active)} active icons; {len(entries)-len(active)} retired allocations; {font_file.stat().st_size} byte TTF')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    generate = commands.add_parser('build')
    for name in ['source', 'map', 'font', 'dart', 'license']:
        generate.add_argument('--' + name, type=Path, required=True)
    generate.add_argument('--family', required=True)
    generate.add_argument('--class-name', required=True)
    generate.add_argument('--review', type=Path)
    generate.add_argument('--previous-map', type=Path)
    for action in ['add', 'retire']:
        sub = commands.add_parser(action)
        sub.add_argument('--map', type=Path, required=True)
        sub.add_argument('--name', required=True)
        if action == 'add':
            sub.add_argument('--file', required=True)
            sub.add_argument('--rtl', action='store_true')
    args = parser.parse_args()
    if args.command == 'build':
        build(args.source, args.map, args.family, args.class_name, args.font, args.dart, args.license, args.review, args.previous_map)
        return
    entries = read_map(args.map)
    if args.command == 'add':
        if any(entry.name == args.name for entry in entries):
            raise ValueError('Existing or retired semantic name cannot be allocated again')
        entries.append(Entry(args.name, max((entry.codepoint for entry in entries), default=0xDFFF) + 1, args.file, args.rtl))
    else:
        if not any(entry.name == args.name for entry in entries):
            raise ValueError('Unknown semantic name')
        entries = [Entry(e.name, e.codepoint, e.file, e.rtl, 'retired' if e.name == args.name else e.status) for e in entries]
    check_history(entries, read_map(args.map))
    write_map(args.map, entries)
    read_map(args.map)

if __name__ == '__main__':
    main()
