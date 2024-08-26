# Yande GUI

The Cross-platform GUI for yande.re

| Platform | View | Download | Verified | Notes          |
|----------|------|----------|----------|----------------|
| Android  | ✅    | ✅        | ✅        |                |
| Windows  | ✅    | ✅        | ✅        |                |
| Linux    | ✅    | ✅        | ✅        |                |
| macOS    | ✅    | ✅        | ✅        |                |
| iOS      | ✅    | ✅        | ✅        | iPadOS support |

# Discussion

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/+ONtNV3HTQ0NhMzVh)
[![Discord](https://img.shields.io/badge/chat-Discord-blue.svg)](https://discord.gg/jQatz6965H)

If you have any questions or suggestions, you can go to Telegram to discuss or open an [Issue](https://github.com/normalllll/yande_gui/issues/new).

We are recruiting artists to draw `icons` for this App

# Screenshots (Desktop)

| ![img0](screenshot/desktop/img0.webp) | ![img1](screenshot/desktop/img1.webp) |
|---------------------------------------|---------------------------------------|

| ![img2](screenshot/desktop/img2.webp) | ![img3](screenshot/desktop/img3.webp) |
|---------------------------------------|---------------------------------------|

# Screenshots (Mobile)

| ![img0](screenshot/mobile/img0.webp) | ![img1](screenshot/mobile/img1.webp) |
|--------------------------------------|--------------------------------------|

| ![img2](screenshot/mobile/img2.webp) | ![img3](screenshot/mobile/img3.webp) |
|--------------------------------------|--------------------------------------|

# Which to download?

| Architecture | Windows                                                                                 | Linux                                                                                       | Android                                                                                             | macOS                                                                                             | iOS                                                                                      |
|--------------|-----------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| x86-64(x64)  | [zip](https://github.com/normalllll/yande_gui/releases/latest/download/windows-x64.zip) | [tar.gz](https://github.com/normalllll/yande_gui/releases/latest/download/linux-x64.tar.gz) | [APK](https://github.com/normalllll/yande_gui/releases/latest/download/app-x86_64-release.apk)      | [zip](https://github.com/normalllll/yande_gui/releases/latest/download/macos-x86_64-nosigned.zip) |                                                                                          |
| ARM64        |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/yande_gui/releases/latest/download/app-arm64-v8a-release.apk)   | [zip](https://github.com/normalllll/yande_gui/releases/latest/download/macos-arm64-nosigned.zip)  | [IPA](https://github.com/normalllll/yande_gui/releases/latest/download/ios-nosigned.ipa) |
| ARM32        |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/yande_gui/releases/latest/download/app-armeabi-v7a-release.apk) |                                                                                                   |                                                                                          |
| Universal    |                                                                                         |                                                                                             | [APK](https://github.com/normalllll/yande_gui/releases/latest/download/app-universal-release.apk)   |                                                                                                   |                                                                                          |


### For Android
Now, mainstream Android devices are generally ARM64. Old Android tablets may be x86-64, and old phones may be ARM32.

Generally, you can download the ARM64 version. If you cannot install it or do not know the architecture of your device, download the universal APK.


### For Windows

Just decompress

### For Linux

Decompress and run the following command to grant execution permissions.
```shell
sudo chmod +x yande_gui
```

### For macOS

Decompress and run the following command to remove the quarantine attribute.
```shell
sudo xattr -r -d com.apple.quarantine yande_gui.app
```

### For iOS

Please sign the IPA file and install it manually.

