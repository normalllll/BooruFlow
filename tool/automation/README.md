# Background Flutter UI automation

Use the installed `flutter-ui-automation` skill for this workflow. No Computer
Use, global keyboard/mouse input or foreground activation is used. The normal
`lib/main.dart` remains unchanged. `flutter_driver` is an explicitly approved
Flutter SDK **dev dependency**; its SDK/transitive tooling dependencies are not
imported by production code.

## Build the complete prerequisites

Windows 10 1903+, Windows SDK/Visual C++, Flutter 3.47.8, Python 3 and FFmpeg /
FFprobe are required. Install the complete skill package, including scripts and
native sources. This build uses Visual Studio 2026. Run from the project root:

```powershell
./tool/automation/build.ps1 -FlutterRoot V:/SDK/flutter -CMake D:/VisualStudio/IDE/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe
```

An alternate skill installation can be supplied with `-SkillRoot`. The native
helper is built into `build/flutter-ui-automation/window-capture/Release/`.
The app goes into `build/automation-windows/x64/runner/Debug/`. It does not
overwrite `build/windows/` or `build/background-windows/`.

`BOORUFLOW_UI_AUTOMATION` is a CMake option, **OFF by default**. Only this isolated
build includes the test native channel. Its first show places the new window at
HWND_BOTTOM with SWP_NOACTIVATE, avoids initial child focus, and chooses the
largest secondary work area with signed physical coordinates and real DPI.
Real user activation remains possible. Do not interact with an existing human
session or launch this harness without the applicable runtime authorization.

## Operate one owned instance

Set `FLUTTER_ROOT` if Flutter is not installed at `V:/SDK/flutter`. Set
`FLUTTER_UI_AUTOMATION_SKILL` for another skill location. FFmpeg and FFprobe must
be on PATH. `python` below means the available native Windows Python executable.

```powershell
python tool/automation/run.py start
python tool/automation/run.py state
python tool/automation/run.py environment
python tool/automation/run.py drive tree
python tool/automation/run.py drive semantics
python tool/automation/run.py request '{"command":"pretendForeground","enabled":true}'
python tool/automation/run.py drive tap text Search
python tool/automation/run.py drive tap type EditableText
python tool/automation/run.py drive text 'sky 测试输入'
python tool/automation/run.py drive text-of type EditableText
python tool/automation/run.py request '{"command":"key","key":"Escape"}'
python tool/automation/run.py request '{"command":"resize","width":500,"height":700}'
python tool/automation/run.py request '{"command":"platformBrightness","value":"light"}'
python tool/automation/run.py pair build/ui-automation/search.png
python tool/automation/run.py record-app build/ui-automation/app.mp4 8 5
python tool/automation/run.py record-window build/ui-automation/window.mp4 8 12
python tool/automation/run.py request '{"command":"pretendForeground","enabled":false}'
python tool/automation/run.py stop
```

Selectors must be observed in the actual widget/render or semantics tree before
use. Supported selectors are `key`, `text`, `semantics`, and `type`; scroll takes
selector kind/value followed by logical dx/dy. Framework key injection supports
Escape, Enter, Tab, Space, and the four arrows. It does not send Windows keys.
The named session stores its PID/VM URI under ignored `build/ui-automation/` and
verifies the executable path before attachment/capture/close. It refuses to
replace a live but unresponsive session. Start allocates a fresh profile there;
all path_provider document/support/cache/temp/download paths are redirected in
the test entrypoint before real bootstrap, including Hive and Rust support data.
No production data, cookies or credentials are copied into it.

First verify natural background operation. Enable framework foreground
simulation only when focus/lifecycle-dependent Flutter behavior needs it;
disable it afterwards and inspect raw/effective state and native activation
count separately. This does not cover native IME, OS shortcuts/dialogs, real
touch, or native plugins that directly inspect Windows activation.

## Capture and evidence

The capture boundary is outside the entire app/Navigator. App PNGs are written at
the actual view DPR. A test-only 24-bit sequence strip at the top edge supplies a
per-request presentation fence. It uses a thin non-interactive area rather than
covering bottom navigation labels. No marker exists in the normal entrypoint.
A bounded forced framework frame plus native redraw request does not by itself
prove presentation: native WGC pixels must contain that exact sequence.

`pair` writes `-app.png` and `-window.png`; a native failure is a command failure,
even when the independent app PNG succeeded. WGC is the selected native backend.
No automatic PrintWindow, Computer Use, renderer, DPR or resolution fallback is
implemented. Neither channel fabricates a native title bar around app pixels.

For publication screenshots, first retain the normal verified `pair`. Then
`request {"command":"captureProbe","enabled":false}` hides only the test strip;
capture the same owned HWND through WGC and inspect that clean native PNG.
The clean capture has no encoded fence and reports `presentationVerified: false`;
keep it distinct from the preceding verified pair. `prepareCapture` automatically
restores the strip for the next verification. Keep original physical-resolution
PNGs; README WebP assets are lossless encodings of the clean native capture.

Recordings retain FFV1/BGRA `.lossless.mkv` masters at original dimensions.
MP4 is an explicitly lossy viewing copy, padded only for H.264 if dimensions are
odd. App recording keeps every original PNG and samples on one Driver connection.
Requested cadence is measured; missing it by more than 10% is an explicit failure.
Decoded BGRA frame hashes are checked **in memory**, without writing manifests,
checksum files, pixel-difference statistics or contact sheets. This does not
establish 60 fps performance, HDR or color-management fidelity. Inspect actual
content and the relevant animation region as well as the file/codec checks.

The first 2026-10-17 integration run failed the native presentation probe in
both BooruFlow and the unmodified skill fixture. The display/lock state was not
recorded for those failures, so their cause cannot be attributed to the skill.
A later comparison, with the same binary/renderer/DPR and explicit display-on,
active, unlocked session observations, passed WGC capture and an 8-second,
12 fps native FFV1 recording (96 verified frames, no foreground samples).

Native capture now subscribes to the current session display state and reads
WTSSessionInfoEx before and after the operation. Display-off, unknown state,
locked or disconnected sessions fail the native preflight with their actual
state; capture errors retain both observations. A display-off event during a
recording also invalidates that run. After the user's additional authorization, a failed capture that observes
`displayState=off` may request `SetThreadExecutionState(ES_DISPLAY_REQUIRED)`
**once**, wait at most 3 seconds for display-on, then retry once with a **new**
presentation probe. An already-on display never triggers a wake or blind retry.
Unknown/locked/disconnected state is not bypassed. No ES_CONTINUOUS, persistent
power-policy change, unlock, foreground activation or input injection is used.
The actual one-shot wake remains unverified until a natural display-off failure
occurs; its decision paths are covered by fake-environment tests. The tool does
not prevent the user from putting the computer to sleep. A CPU that is actually
suspended cannot execute the capture; a running process alone does not establish
that Windows is presenting the interactive desktop. Earlier failures remain
recorded as failed attempts, not retroactively accepted captures.

The test host can simulate the **platform brightness input** with
`platformBrightness: light/dark/system` so system-mode App themes can be checked
before all settings pages are rebuilt. It overrides MediaQuery only in the test
entrypoint, preserves view metrics and Navigator State, and changes neither
business settings nor the Windows theme. Explicit App appearance modes keep
their normal precedence. Restore `system` before closing. The capture remains
real WGC pixels of the rendered test window; the brightness input is simulated.

## Internal hover and mouse activation

`request {"command":"pointer","action":"hover","x":100,"y":100}` moves only a dedicated Flutter mouse pointer. Coordinates must come from an observed Driver `center` result and stay inside the current logical Flutter view. `action:tap` dispatches mouse down/up through GestureBinding; `action:remove` removes this synthetic pointer. It does not move the Windows cursor, send native input or focus the HWND. The close command removes it before disposing the owned test window. This completes the hover-only action path that ordinary Driver touch taps cannot activate reliably.

For repeated labels, use selector kind `scoped` with JSON `{"of":{"kind":"type","value":"FrostInspector"},"matching":{"kind":"semantics","value":"Close"}}`. This composes standard Driver descendant finders; both ancestor and target must first be observed in the actual tree. It avoids guessing screen coordinates or activating the native window.


## Confirmed preview boards

`python tool/automation/run.py start B01` starts a fresh, isolated board fixture;
a live session with a different board is rejected. `preview/capture.py B01 B02`
reads each confirmed canvas dimension and places only that owned background HWND
with HWND_BOTTOM / SWP_NOACTIVATE, then saves the original paired PNGs. Stop waits
for that process to exit instead of reusing a closing VM. Fixture services live
only under tool/automation/preview and keep production request/decode/UI paths.
Phone boards simulate Flutter Android and 47/34 insets below MaterialApp; their
Windows capture is not a real Android device, keyboard, IME or touch acceptance.
The normal main entrypoint never imports these fixtures.

Internal pointer actions also include `secondaryTap` and `longPress`, dispatched
through GestureBinding after observing actual selectors. `pumpFrames` (1–120)
forces bounded frames for a specific transition, without waiting forever on
loading/skeleton animations and without foreground activation. Read actual
widget/render state after pumping; elapsed time alone does not prove loading.


## R4 performance fixture

`build.ps1 -Configuration Profile` builds the same isolated runner in
`runner/Profile`. Set `BOORUFLOW_AUTOMATION_CONFIGURATION=Profile` for run.py;
Debug remains the default. Profile is Windows-only (phone platform simulation
requires Debug). Board L12 supplies three distinct 208-task saved batches and
five singles (629 tasks), without reading user storage. `frameTimings` returns
and clears actual FrameTiming build/raster/total microseconds. The profile
render/semantics debug tree is unavailable; inspect its app PNG and use observed
text controls for Driver events. No foreground, mouse or keyboard takeover is
introduced. B04 now captures same-list refresh; switching list keys must display
the destination's own cached results or initial skeleton instead.


## R5 media fixtures

`preview/capture_media.py [M01 M02 ...]` captures only owned background test
windows. M01 mixes video/static/animation covers; M02 uses the actual Danbooru
#12408475 metadata with repository-generated cover art; M03 decodes the local
two-frame GIF; M04 supplies an unsupported SWF. These are controlled media
fixtures, not captures of upstream artwork or proof of video playback. The
runner passes the absolute test fixture directory through
BOORUFLOW_AUTOMATION_FIXTURES because the executable's working directory is its
bundle. The normal entrypoint never reads this variable.


## R5 native playback validation

`release_video.dart` is an isolated Windows AOT test entrypoint, enabled only
with the existing default-OFF native automation option. Its serial file RPC
reuses the same internal event handlers and original-DPR WGC presentation probe;
it does not enable Driver or control the host foreground. `release_video.py`
checks MP4/WebM decoding, time advancement, exact five-second keyboard seek and
lifecycle disposal. AOT key events supply explicit physical codes because SDK
debug key names are absent in Release.

M05 is local WebM; M06 is a deliberately invalid 16-byte stream. The generated
12-second test videos have no audio and are codec/UI fixtures, not authenticated
upstream acceptance. Their test-only local server supports byte ranges; the
production Rust capability relay has separate actual socket/range/cancellation
tests. Normal main never imports these fixture servers or test controls.


## Android 16 KB acceptance

`android.dart` is a separate Android test entrypoint with isolated app storage.
It exposes serial loopback HTTP controls on device port 9415; `android.py`
forwards only the authorized `emulator-5580` to host port 9416. Android uses its
actual IME and view insets: it does not register the Windows Driver text
emulation or use Windows focus suppression. The normal main never imports it.
The existing Pixel_10_Pro_XL is launched headlessly with read-only user data,
without snapshots, and the owned process is closed after verification.

Debug/JIT starts on this host caused the emulator process to exit with
0xC0000005; AOT is the explicitly recorded diagnostic comparison, not a silent
capture fallback. Local media files are copied into the isolated app before
replacing the Debug setup APK with the local-test-signed Release fixture. The
three codec fixtures are not bundled into the production app. M07 is animated
WebP and M08 is AVIF; preview cache keys include board and URL so switching
fixtures in the same Android process cannot reuse another type's pixels.

Read-only commands `inputs`, `texts`, `buttons`, `mediaDiagnostics` and
`videoDiagnostics` expose actual render/controller state. Adb screenshot and
screenrecord capture the emulator only, never the host desktop. Phone board
SafeArea is simulated only on Windows; Android keeps actual system insets.


Build the Android Debug entrypoint once for isolated `run-as` fixture-file setup,
then build the same entrypoint as Release for the actual AOT check:
`flutter build apk --debug --target tool/automation/android.dart --target-platform android-x64`,
then `flutter build apk --release --target tool/automation/android.dart --target-platform android-x64`.
Save that test APK as `build/android-validation/booruflow-ui-fixture-x64.apk`.
The client refuses to substitute the normal `app-release.apk`. The final normal
Release build is kept separately and restored to its standard output path.
`android_sdk_probe.dart` is a minimal media_kit diagnostic (local file/local HTTP,
without App/Frost/Rust bootstrap); it is not a replacement UI or accepted player.
Native Android video acceptance is pending; see BOORUFLOW_R5_ANDROID_VALIDATION.


## R6 Android rendering regression

Select an explicitly authorized, observed emulator with
`BOORUFLOW_ANDROID_SERIAL` (default remains `emulator-5580`). R6 used the user's
existing visible `Pixel_10_Pro_XL` on `emulator-5554` after direct authorization;
adb input/capture affects the guest only. Do not close unrelated emulators or
kill the shared adb server. No data wipe or AVD configuration edit is needed.

`android_sdk_probe.dart` is the minimal current media_kit baseline. It retains
bounded native logs and actual texture dimensions, and supports local MP4/WebM.
The approved Android production output is `mediacodec_embed` / `mediacodec`;
Flutter's renderer and dependency versions are unchanged. The earlier default
GPU/EGL failure evidence is preserved under `build/android-validation/r6/`.
`android_glass_probe.dart` compares deferred blur, real blur and an uncovered
high-contrast background using the actual shared material.

Read-only `navigationDiagnostics` reports the actual route, viewer/detail/video
widget counts and Overlay count; `glassDiagnostics` reports actual material
reveal scopes and geometry. `videoDiagnostics.closed` means native close has
completed, while `closing` means it is still in progress. A retained offstage
PostVideo widget is not a second active decoder.

Do not treat `ready`, dimensions, or an opened route as presentation evidence.
Before a static fullscreen shot, wait for the relevant onMedia material scopes'
opacity and nested progress to reach one, then request frames. R6's first two
fullscreen shots were caught mid-transition and were retained as diagnostics;
the final originals were recaptured after this target-specific wait. Use two
native adb frames with advancing encoded picture content to prove playback.
The Windows WGC presentation probe does not apply to adb captures.

### Concurrent Android tasks

Use a distinct AVD and explicit `BOORUFLOW_ANDROID_SERIAL` for each task.
Set `BOORUFLOW_ANDROID_RPC_PORT` to a free host port (default 9416); forwarding
uses `--no-rebind` so another task cannot be silently displaced. The device-local
9415 endpoint is isolated by device. Never kill the shared ADB server or remove
all forwards. Remove only the task-owned forward after verification. AVDs still
share host CPU, GPU and memory; serialize heavy verification and monitor load.

## Owned Debug file controls

`debug_window.dart` uses the same isolated profile and file RPC as
`release_video.dart`, with Debug assertions enabled. `flutterErrors` returns all
framework error messages and stacks without swallowing the normal error handler.
In this dedicated Windows Debug target, `enterText` feeds the SDK Driver's
emulated input channel after an observed editable has been tapped; it never
assigns an App text controller or sends native keys. Release does not promise
this Debug Driver capability and reports a prerequisite error when unavailable.
`inputs` reports the actual editable rectangle and selection for geometry checks.

`resize` dimensions now denote Flutter client logical pixels, including a measured
custom frame correction. Select `BOORUFLOW_AUTOMATION_PLACEMENT=primary` when the
secondary work area cannot fit a requested viewport. The request is still capped
by that monitor, so always validate `state.viewSize / pixelRatio` before naming a
screenshot by width. Placement/resizing preserve non-activation and background
Z-order. `historicalPostFixture` exercises the real no-extra post route using a
source/id pair in an isolated fixture; it does not access user download records.

R8 file-reveal fixtures: `BOORUFLOW_R8_REVEAL_FIXTURE=missing` or `fileMissing` in the dedicated preview entrypoint injects filesystem results and records process intents only. It never launches Explorer or probes a user's downloads. Unset it for the production reveal implementation.


### Build target preflight

A normal Flutter build rewrites windows/flutter/ephemeral/generated_config.cmake.
Before rebuilding the background runner, configure its dedicated target again;
use build.ps1 -Target tool/automation/debug_window.dart for Debug file controls,
or the default main.dart for VM Driver. Do not call CMake alone after a normal
Release build. Both Python launchers verify the bundled isolated-profile marker
before creating a profile or starting a process, and reject the wrong entrypoint.
Run `python -m unittest discover -s tool/automation -p test_bundle_guard.py` to
verify this refusal with temporary fake bundles (no App process).

Pressed-state captures use `request {"command":"touch","action":"down","x":X,"y":Y}`
after observing actual control bounds. Capture, then send `action:cancel` (or
`up` to activate). This holds a separate Flutter touch pointer, never host or
device input. Always cancel a held pointer in the script cleanup.

For a held desktop press use the same `touch` hook with `kind:"mouse"` on down;
up/cancel retain that kind. This avoids invoking touch-only long-press menus
while capturing a pointer press. It is still framework-only input.


## R19 icon overview

Board `R19` renders all app-owned glyphs from the generated const mapping. Its
LTR/RTL button changes only the diagnostic subtree's Directionality; it does not
change product locale or settings. The fixture exists only in test entrypoints.
Use the existing actual-window/device capture path to verify font loading and
mirroring. Production main never imports this gallery.


### Rounded highlight composition comparison

Board `R19AA` is a diagnostic, not a product rendering variant. It compares the
current shaped base/highlight plus anti-aliased clip, the same shapes using
antiAliasWithSaveLayer, and rectangular base/highlight fills with a single final
anti-aliased saveLayer clip. All columns have the same physical pixel phase at
DPR 1.5; rows use alpha 0, .08 and .16. The 2026-10-24 native comparison did not
establish an outer-corner improvement, so no saveLayer change was applied to the
library. Retain the overview for reproducible investigation without modifying
normal main or selecting a different backend.


### Asymmetric superellipse fill diagnostics (R19 follow-up)

`R19SE` renders a standalone Flutter-only comparison of native shape fill,
rectangle under native clip, rectangle under path clip, and native clip with
saveLayer. It has its own `main()` in `preview/superellipse_seams.dart` so the
same geometry can be copied into a clean Flutter project. `R19SC` exercises the
real grouped rows, stepper ends, segments and asymmetric surface roles. These
boards are isolated from production main and use the existing owned background
Windows runner and native presentation fence. They do not change the renderer.
The controlled Impeller/Skia diagnostic and issue draft are documented in
`V:/Code/frost_ui/docs/experiments/r19-superellipse-repro/ISSUE_DRAFT.md`.


`R20MC` injects a structured image challenge failure through the real preview
feed/card/recovery path. It is for native error-card hover/held-press verification;
it neither opens a WebView nor contacts a source site. Displayed-image scale
registration is covered by the shared widget tests, including first-frame and
full clipped-card press geometry.

### Shared operation-error notice fixture

`operationFailureToast` injects an explicitly test-only `BooruError` through
`AppToast.errorWithCause` in the normal App root. The marker
`stage=fixture-webview-create` and diagnostic ID `toast-layout-fixture` distinguish
layout evidence from a real native WebView failure. No validation window or
remote request is started. Use observed buttons to open the shared details dialog.
