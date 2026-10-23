# Development

[Back to README](README.md)

## Build from source

### Toolchains

- **Flutter 3.47.6 stable**, pinned in [the CI setup action](.github/actions/setup/action.yml).
- **Rust 1.99.1** through rustup, pinned in [rust/rust-toolchain.toml](rust/rust-toolchain.toml). CI reads this file directly.
- Platform tools: Visual Studio C++ desktop tools on Windows; Xcode on macOS for Apple builds; Android SDK and Java 21 for Android; Clang, CMake, Ninja, pkg-config, GTK 3, liblzma, libmpv, and libepoxy development headers on Linux.
- Android builds use SDK 37 and NDK `28.2.13676358`, as configured in the Android project.

```bash
git clone https://github.com/normalllll/yande_gui.git
cd yande_gui
flutter pub get
flutter doctor
flutter run
```

Flutter Native Assets builds and bundles the Rust library automatically. After changing Rust APIs or generated bridge code, stop the app and rebuild it; hot reload cannot replace the native library.

The shared `frost_window` plugin supports both Swift Package Manager and
CocoaPods using one Swift source directory. Flutter can mix SPM plugins with
CocoaPods-only media dependencies. Keep Xcode's default architecture selection;
custom per-configuration `ARCHS` indirection can prevent CocoaPods from analyzing
the Runner target. Debug still builds the active architecture, while Release
keeps the standard architecture set. Before building on macOS, run
`bash tool/ci/prepare_macos_media.sh` after `flutter pub get`; this retries native
media downloads and reports setup failures before compiling Swift.

### Code generation and checks

Install the bridge generator only when modifying the Rust API:

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
flutter_rust_bridge_codegen generate
```

The UI depends on the shared `frost_ui` Git package. A local checkout can be used
without changing the tracked dependency by creating an ignored `pubspec_overrides.yaml`:

```yaml
dependency_overrides:
  frost_ui:
    path: ../frost_ui/packages/frost_ui
```

For Dart models, providers, database code, or translations that use build_runner:

```bash
dart run build_runner build
```

Slang uses its supported legacy writer because the current post-processing writer
conflicts with existing generated outputs in build_runner 2.16. Both generation
and CLI audits share the YAML-anchored options in `build.yaml`. Generated Dart
uses the repository's default 80-column formatting.

Run the project checks locally:

```bash
flutter analyze
flutter test
cargo +1.99.1 fmt --manifest-path rust/Cargo.toml -- --check
cargo +1.99.1 test --manifest-path rust/Cargo.toml --locked
dart run slang analyze --full --outdir=.dart_tool/i18n_audit
```

Do not track lock files. Review dependency changes when upgrading the SDK.

## CI and releases

Linux DEB/RPM packages declare their system media libraries as dependencies.
For the portable Linux tarball, install GTK 3, libstdc++, libmpv, and libepoxy
through your distribution's package manager before launching the app. On
Ubuntu 24.04: `sudo apt install libgtk-3-0t64 libstdc++6 libmpv2 libepoxy0`.

[Flutter Build & Release](.github/workflows/main.yml) builds all five platforms and uploads artifacts. Each build uses read-only repository permissions; a separate job publishes after all platform builds succeed.

- **Manual build:** Open Actions → Flutter Build & Release → Run workflow. Select `main` and leave `publish_release` unchecked to build artifacts and warm default-branch caches without creating a release. Artifacts are retained for 14 days.
- **Tag release:** Push a tag matching `pubspec.yaml`, in the form `v<major>.<minor>.<patch>+<build>` (for example, `v0.10.0+37`). A mismatched tag fails validation before building.
- **Manual publication:** Select an existing version tag and enable `publish_release`. Publishing from a branch is rejected.
- **Android signing:** Configure `KEYSTORE_FILE` (base64-encoded JKS), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` in the `apk-release` environment or repository secrets. Manual builds also require these secrets and any environment approval rules to be satisfied.

### Cache behavior

Flutter SDK, Pub packages, and Cargo downloads are cached separately. CI prefetches Rust dependencies for the requested target architectures with retries, so download failures are visible before the Native Assets hook buffers compiler output. Gradle uses `setup-gradle`; Rust compilation uses sccache because Native Assets chooses its own target directories. The workflow does not cache the entire `.dart_tool` directory or assume native builds write into `rust/target`.

The job summary shows exact Flutter/Pub/Cargo cache hits; Gradle and sccache report their own statistics. A dependency cache hit does not mean every compiler invocation will be cached. GitHub isolates caches between different tags; tag builds can reuse caches from the default branch. Run a manual build on `main` after SDK/dependency upgrades to refresh those caches. The first build with new SDK versions is expected to have cold caches.

### Background Flutter UI verification

Use the installed `flutter-ui-automation` skill and the isolated
[Driver/capture harness](tool/automation/README.md) for screenshots, recordings
and runtime UI checks. It keeps automation out of the normal entrypoint and
preserves the human foreground window. Native presentation failures must remain
explicit; app PNGs do not substitute for native window evidence.
