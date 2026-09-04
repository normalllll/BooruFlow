# BooruFlow

**A cross-platform browser for multiple booru image sources**

BooruFlow provides one consistent interface for searching, browsing, viewing, and downloading artwork from multiple booru-compatible sources. It is available on Android, iOS, Windows, macOS, and Linux.

![Screenshot](screenshots/0.webp)

---

## Features

- 🌐 **Multiple Sources**: Yande.re, Konachan.net, Danbooru, AIBooru, Gelbooru, Wallhaven, and Anime-Pictures.
- 🔎 **Unified Discovery**: Search, rating filters, waterfall browsing, post details, and original-image viewing.
- ⬇️ **Reliable Downloads**: Source-aware folders, post-ID filenames, resumable native downloads, validation, proxy support, and Host/SNI fallback routing.
- 💻 **Cross-Platform**: Android, iOS, Windows, macOS, and Linux.

---

## Contributing

We welcome contributions from the community!

- 🛠 **Bug Reports**: Found a bug? Open an issue on the [issue tracker](https://github.com/normalllll/BooruFlow/issues).
- 🌟 **Feature Requests**: Want to add a new feature? Feel free to propose your ideas!
- 🎨 **Design Contributions**: Visual and interaction design contributions are welcome.

---

## Community

Join the discussion and connect with other users and developers!

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/+ONtNV3HTQ0NhMzVh)
[![Discord](https://img.shields.io/badge/chat-Discord-blue.svg)](https://discord.gg/jQatz6965H)

---

## Downloads

| Architecture | Windows                                                                                 | Linux                                                                                       | Android                                                                                             | macOS                                                                                             | iOS                                                                                      |
|--------------|-----------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| x86-64(x64)  | [zip](https://github.com/normalllll/BooruFlow/releases/latest/download/windows-x64.zip) | [tar.gz](https://github.com/normalllll/BooruFlow/releases/latest/download/linux-x64.tar.gz) | [APK](https://github.com/normalllll/BooruFlow/releases/latest/download/app-x86_64-release.apk)      | [zip](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-x86_64-nosigned.zip) |                                                                                          |
| ARM64        |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/BooruFlow/releases/latest/download/app-arm64-v8a-release.apk)   | [zip](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-arm64-nosigned.zip)  | [IPA](https://github.com/normalllll/BooruFlow/releases/latest/download/ios-nosigned.ipa) |
| ARM32        |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/BooruFlow/releases/latest/download/app-armeabi-v7a-release.apk) |                                                                                                   |                                                                                          |
| Universal    |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/BooruFlow/releases/latest/download/app-universal-release.apk)   |                                                                                                   |                                                                                          |

Visit the [releases page](https://github.com/normalllll/BooruFlow/releases) for more details on the latest versions.

---


## Getting Started

### Prerequisites

Before building or running BooruFlow, install the following dependencies:

- [Flutter](https://flutter.dev/docs/get-started/install): A cross-platform UI toolkit.
- [Rust](https://www.rust-lang.org/tools/install): A powerful, performance-oriented programming language.
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge): A tool for integrating Flutter and Rust.

### Installation

1. **Install Flutter** by following the [official guide](https://flutter.dev/docs/get-started/install).
2. **Install Rust** using `rustup` by following the [official guide](https://www.rust-lang.org/tools/install).
3. **Install flutter_rust_bridge 2.13.0** by running the following command:

    ```bash
    cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
    ```

   Regenerate the bridge after changing the Rust API with
   `flutter_rust_bridge_codegen generate`. Native libraries are built and
   bundled through Flutter Native Assets; Cargokit is not required.

4. Clone the repository:

    ```bash
    git clone https://github.com/normalllll/BooruFlow.git
    cd BooruFlow
    ```

5. Run the app:

    ```bash
    flutter run
    ```

---

## Screenshots

### Desktop

| ![Desktop Screenshot 1](screenshots/desktop/img0.webp) | ![Desktop Screenshot 2](screenshots/desktop/img1.webp) |
|--------------------------------------------------------|--------------------------------------------------------|

### Mobile

| ![Mobile Screenshot 1](screenshots/mobile/img0.webp) | ![Mobile Screenshot 2](screenshots/mobile/img1.webp) |
|------------------------------------------------------|------------------------------------------------------|

---


## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](https://github.com/normalllll/BooruFlow/blob/main/LICENSE) file for more details.
