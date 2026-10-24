# BooruFlow

English | [简体中文](README_zh_cn.md)

**An open-source, cross-platform booru browser and image downloader.**

Search, browse, and download artwork from Danbooru, Gelbooru, Yande.re, and other image sources on Android, Windows, Linux, macOS, and iOS.

[Download](https://github.com/normalllll/BooruFlow/releases/latest) · [Features](#features) · [Screenshots](#screenshots)

![Windows — Yande.re search results for muryo](screenshots/0.webp)

## Features

- **Adaptive interface:** Compact navigation on phones, an expandable sidebar on wider screens, and layouts for touch and pointer input.
- **Desktop window integration:** App content shares the title region on Windows and Linux. macOS keeps its native traffic lights above app navigation; Linux window controls follow the desktop's button layout and icon theme where available.
- **Multiple sources:** Yande.re, Konachan.net, Konachan.com, Danbooru, AIBooru, Gelbooru, Wallhaven, and Anime-Pictures.
- **Search and discovery:** Tag search, rating filters, waterfall browsing, and popular posts where supported.
- **Media viewing:** Explore images, videos, tags, attribution, metadata, and related posts, with fullscreen zooming, panning, and pull-down dismissal.
- **Download management:** Group batch downloads, inspect individual tasks, track progress, pause and resume transfers, retry failures, and organize files by source.
- **Accounts and networking:** Separate accounts for each source, shared proxy settings, connection diagnostics, and web verification on supported platforms.
- **Personalization:** Themes, background effects, layout settings, tag translations, and English, Simplified Chinese, Traditional Chinese, and Japanese interfaces.

Source features and account requirements vary by site. Keep the app running while downloading; transfers may pause if the system suspends or terminates it.

## Download and install

Download packages from [GitHub Releases](https://github.com/normalllll/BooruFlow/releases/latest).

| Platform | Package | Installation |
|---|---|---|
| Android | [app-arm64-v8a-release.apk](https://github.com/normalllll/BooruFlow/releases/latest/download/app-arm64-v8a-release.apk) | Android 8.0+. Suitable for most current phones. Choose [app-universal-release.apk](https://github.com/normalllll/BooruFlow/releases/latest/download/app-universal-release.apk) if unsure about your architecture |
| Windows | [windows-x64.zip](https://github.com/normalllll/BooruFlow/releases/latest/download/windows-x64.zip) | Extract the archive and run the app |
| Linux | [linux_amd64.deb](https://github.com/normalllll/BooruFlow/releases/latest/download/linux_amd64.deb), [linux_amd64.rpm](https://github.com/normalllll/BooruFlow/releases/latest/download/linux_amd64.rpm), or [linux-x64.tar.gz](https://github.com/normalllll/BooruFlow/releases/latest/download/linux-x64.tar.gz) | Choose the package for your distribution. Builds target Ubuntu 24.04; older systems may lack required libraries |
| macOS | [ARM64](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-arm64-nosigned.zip), [x86_64](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-x86_64-nosigned.zip) | Minimum build target: macOS 12. Separate builds for Apple Silicon and Intel. The apps are not notarized |
| iOS | [ios-nosigned.ipa](https://github.com/normalllll/BooruFlow/releases/latest/download/ios-nosigned.ipa) | iOS 15+. Requires signing before installation |

Android ARM32 and x86_64 packages are also available. Check the release assets for the packages included in each version.

Linux DEB/RPM packages declare their runtime dependencies. The portable archive requires GTK 3, libstdc++, libmpv, and libepoxy to be installed separately; see the [Linux dependency instructions](DEVELOPMENT.md#ci-and-releases). The macOS build target above is a technical minimum; use systems within Flutter's and the OS vendor's maintained support range.

On iOS, supported images and videos are saved to Photos; archives and formats that Photos cannot reliably preserve are saved to Files. Individual photo saves request add-only access, while batch downloads that create and reuse albums require full Photos access.

## Contributing

Report bugs or suggest features in [Issues](https://github.com/normalllll/BooruFlow/issues). For bugs, include your platform, image source, and steps to reproduce. Code, design, and translation contributions are welcome.

See the [development guide](DEVELOPMENT.md) for building, testing, and release instructions.

## Community

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/+ONtNV3HTQ0NhMzVh)
[![Discord](https://img.shields.io/badge/chat-Discord-blue.svg)](https://discord.gg/jQatz6965H)

## Screenshots

### Windows

| ![Yande.re search results for muryo](screenshots/desktop/img0.webp) | ![Details of the second search result](screenshots/desktop/img1.webp) |
|--------------------------------------------------------|--------------------------------------------------------|

### iOS Simulator

| ![Anime-Pictures home](screenshots/mobile/img0.webp) | ![Yande.re search page with the keyboard hidden](screenshots/mobile/img1.webp) |
|------------------------------------------------------|------------------------------------------------------|

## License

Licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
