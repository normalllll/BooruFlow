enum Resolution {
  zero('', 0),
  sd('SD', 720 * 480),
  hd('HD', 1280 * 720),
  r1k('1K', 1920 * 1080),
  r2k('2K', 2560 * 1440),
  r4k('4K', 4096 * 2160),
  r8k('8K', 7680 * 4320),
  r16k("16K", 30720 * 17280),
  r32k("32K", 61440 * 34560),
  r64k("64K", 122880 * 69120);

  final String title;
  final int resolution;

  const Resolution(this.title, this.resolution);

  double get px => resolution.toDouble();

  static Resolution match(int px) {
    return Resolution.values.reversed.firstWhere(
      (res) => px >= res.px,
      orElse: () => Resolution.zero,
    );
  }
}
