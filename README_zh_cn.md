# BooruFlow

[English](README.md) | 简体中文

**开源的跨平台 Booru 图片浏览与下载工具。**

在 Android、Windows、Linux、macOS 和 iOS 上搜索、浏览与下载来自 Danbooru、Gelbooru、Yande.re 等图源的图片。

[下载最新版](https://github.com/normalllll/BooruFlow/releases/latest) · [功能](#功能) · [截图](#截图)

![桌面端：Yande.re 搜索 muryo 的瀑布页](screenshots/0.webp)

## 功能

- **自适应界面：** 手机使用紧凑导航，宽屏使用可展开侧栏，布局适配触屏和鼠标操作。
- **桌面窗口集成：** Windows、Linux 将应用内容融入标题区域；macOS 在应用导航上方保留原生红黄绿按钮，Linux 在可用时遵循桌面的按钮排布与图标主题。
- **多个图源：** Yande.re、Konachan.net、Konachan.com、Danbooru、AIBooru、Gelbooru、Wallhaven 和 Anime-Pictures。
- **搜索与发现：** 标签搜索、分级筛选、瀑布流，以及图源支持的热门图片。
- **媒体浏览：** 查看图片、视频、标签、作者与来源、元数据和关联帖子，支持全屏缩放、平移和下拉关闭。
- **下载管理：** 按批次分组，查看单个任务详情与进度，暂停、继续或重试下载，并按图源整理文件。
- **账号与网络：** 按图源保存账号，统一配置代理，提供连接诊断，以及受支持平台上的网页验证。
- **个性化：** 主题、背景效果、布局设置、标签翻译，以及简体中文、繁体中文、英语和日语界面。

各图源提供的功能和账号要求有所不同。下载时请保持应用运行；系统挂起或结束应用后，传输可能中断。

## 下载与安装

从 [GitHub Releases](https://github.com/normalllll/BooruFlow/releases/latest) 下载安装包。

| 平台 | 安装包 | 安装说明 |
|---|---|---|
| Android | [app-arm64-v8a-release.apk](https://github.com/normalllll/BooruFlow/releases/latest/download/app-arm64-v8a-release.apk) | Android 8.0 及以上；适合大多数当前手机，不确定架构时选择 [app-universal-release.apk](https://github.com/normalllll/BooruFlow/releases/latest/download/app-universal-release.apk) |
| Windows | [windows-x64.zip](https://github.com/normalllll/BooruFlow/releases/latest/download/windows-x64.zip) | 解压后运行应用 |
| Linux | [linux_amd64.deb](https://github.com/normalllll/BooruFlow/releases/latest/download/linux_amd64.deb)、[linux_amd64.rpm](https://github.com/normalllll/BooruFlow/releases/latest/download/linux_amd64.rpm) 或 [linux-x64.tar.gz](https://github.com/normalllll/BooruFlow/releases/latest/download/linux-x64.tar.gz) | 按发行版选择。基于 Ubuntu 24.04 构建，旧系统可能缺少所需库 |
| macOS | [ARM64](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-arm64-nosigned.zip)、[x86_64](https://github.com/normalllll/BooruFlow/releases/latest/download/macos-x86_64-nosigned.zip) | 最低构建目标为 macOS 12；分别为 Apple Silicon 和 Intel 构建，应用未经公证 |
| iOS | [ios-nosigned.ipa](https://github.com/normalllll/BooruFlow/releases/latest/download/ios-nosigned.ipa) | iOS 15 及以上；安装前需要自行签名 |

Android 另提供 ARM32 和 x86_64 安装包，各版本可用包以发行版附件为准。

Linux DEB/RPM 包声明了运行库依赖；便携压缩包需要另外安装 GTK 3、libstdc++、libmpv 和 libepoxy，参见 [Linux 依赖说明](DEVELOPMENT.md#ci-and-releases)。上述 macOS 构建目标是技术下限；实际使用应处于 Flutter 和系统厂商仍维护的支持范围内。

iOS 会将支持的图片与视频保存到“照片”，压缩包和“照片”无法可靠保留的格式则保存到“文件”。单张保存只申请添加照片权限；需要创建和复用相簿的批量下载才申请完整照片访问。

图片加载失败时，先检查网络连接和图源的账号要求，再检查应用的网络设置；必要时可以尝试使用代理。

## 参与贡献

欢迎在 [Issues](https://github.com/normalllll/BooruFlow/issues) 报告问题或提出建议。报告问题时，请提供平台、图源和复现步骤。也欢迎贡献代码、设计和翻译。

构建、测试和发布说明见[开发指南](DEVELOPMENT.md)。

## 社区

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/+ONtNV3HTQ0NhMzVh)
[![Discord](https://img.shields.io/badge/chat-Discord-blue.svg)](https://discord.gg/jQatz6965H)

## 截图

### 桌面端

| ![Yande.re 搜索 muryo 的瀑布页](screenshots/desktop/img0.webp) | ![搜索结果第二张图片的详情页](screenshots/desktop/img1.webp) |
|--------------------------------------------------------|--------------------------------------------------------|

### 移动端

| ![Anime-Pictures 首页](screenshots/mobile/img0.webp) | ![Yande.re 搜索输入页，键盘收起](screenshots/mobile/img1.webp) |
|------------------------------------------------------|------------------------------------------------------|

## 许可证

本项目采用 GNU General Public License v3.0，详见 [LICENSE](LICENSE)。
