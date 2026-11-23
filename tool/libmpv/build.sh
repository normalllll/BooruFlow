#!/bin/bash
# Builds the reduced libmpv that BooruFlow ships instead of media_kit's prebuilt
# libraries, for Windows, Android, macOS and iOS. Runs on macOS; see
# tool/README.md for the prerequisites and how a build is published.
#
#   tool/libmpv/build.sh              every target, then the release archives
#   tool/libmpv/build.sh TARGET...    only these targets
#
# Targets: windows-x86_64, android-arm64-v8a, android-armeabi-v7a,
# android-x86_64, macos-arm64, macos-x86_64, ios-arm64, iossim-arm64,
# iossim-x86_64.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
WORK=${LIBMPV_WORK:-$REPO/build/libmpv}
NDK=${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/28.2.13676358}
JOBS=$(sysctl -n hw.ncpu)
ALL_TARGETS="windows-x86_64 android-arm64-v8a android-armeabi-v7a android-x86_64
  macos-arm64 macos-x86_64 ios-arm64 iossim-arm64 iossim-x86_64"

LLVM_MINGW_VERSION=20261117
LLVM_MINGW=llvm-mingw-$LLVM_MINGW_VERSION-ucrt-macos-universal
LLVM_MINGW_URL=https://github.com/mstorsjo/llvm-mingw/releases/download/$LLVM_MINGW_VERSION/$LLVM_MINGW.tar.xz
# EGL and ANGLE headers for mpv's ANGLE interop; the same archive media_kit's
# Windows package ships its ANGLE libraries from.
ANGLE_URL=https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES/releases/download/v1.0.1/ANGLE.7z
ANGLE_SHA256=cc5911bb15d596fd5a2b362613ad35b7093b427117269a7359054a65746a5f9a

SRC=$WORK/src
mkdir -p "$SRC" "$WORK/toolchains"

for tool in meson ninja nasm cmake pkg-config git python3 xcrun; do
  command -v $tool > /dev/null || { echo "missing $tool (brew install meson ninja nasm cmake pkgconf)"; exit 1; }
done

fetch() {
  local name=$1 url=$2 ref=$3
  [ -d "$SRC/$name" ] && return
  git clone -q --depth 1 --branch "$ref" --recurse-submodules --shallow-submodules "$url" "$SRC/$name"
}
fetch ffmpeg https://github.com/FFmpeg/FFmpeg.git n8.1.3
fetch mpv https://github.com/mpv-player/mpv.git v0.42.0
fetch dav1d https://code.videolan.org/videolan/dav1d.git 1.5.3
fetch libplacebo https://code.videolan.org/videolan/libplacebo.git v7.387.0
fetch freetype https://gitlab.freedesktop.org/freetype/freetype.git VER-2-14-3
fetch harfbuzz https://github.com/harfbuzz/harfbuzz.git 15.2.0
fetch fribidi https://github.com/fribidi/fribidi.git v1.0.18
fetch libass https://github.com/libass/libass.git 0.17.5
fetch mbedtls https://github.com/Mbed-TLS/mbedtls.git v3.6.8
python3 "$HERE/patch_mac_gl.py" "$SRC/mpv/meson.build"
python3 "$HERE/patch_audiounit.py" "$SRC/mpv/audio/out/ao_audiounit.m"

build_target() {
TARGET=$1
BUILD=$WORK/build/$TARGET
PREFIX=$WORK/prefix/$TARGET
OUT=$WORK/out/$TARGET
mkdir -p "$BUILD" "$PREFIX" "$OUT"
echo "== $TARGET"

COMMON_CFLAGS="-ffunction-sections -fdata-sections"
case $TARGET in
  windows-x86_64)
    OS=windows
    if [ ! -d "$WORK/toolchains/$LLVM_MINGW" ]; then
      curl -sSfL "$LLVM_MINGW_URL" | tar -xJ -C "$WORK/toolchains"
    fi
    if [ ! -d "$WORK/angle/include" ]; then
      mkdir -p "$WORK/angle"
      curl -sSfL -o "$WORK/angle/ANGLE.7z" "$ANGLE_URL"
      echo "$ANGLE_SHA256  $WORK/angle/ANGLE.7z" | shasum -a 256 -c - > /dev/null
      tar -xf "$WORK/angle/ANGLE.7z" -C "$WORK/angle" include
    fi
    export PATH="$WORK/toolchains/$LLVM_MINGW/bin:$PATH"
    HOST=x86_64-w64-mingw32
    CC=$HOST-clang; CXX=$HOST-clang++; AR=$HOST-ar; NM=$HOST-nm; RANLIB=$HOST-ranlib; STRIP=$HOST-strip
    SYSTEM=windows; CPU_FAMILY=x86_64; CPU=x86_64
    FF_OS=mingw32; FF_ARCH=x86_64
    EXTRA_CFLAGS="-I$WORK/angle/include"
    ;;
  android-*)
    OS=android
    export PATH="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"
    API=26
    case $TARGET in
      android-arm64-v8a) CLANG=aarch64-linux-android$API; CPU_FAMILY=aarch64; CPU=armv8; FF_ARCH=aarch64; ABI=arm64-v8a ;;
      android-armeabi-v7a) CLANG=armv7a-linux-androideabi$API; CPU_FAMILY=arm; CPU=armv7; FF_ARCH=arm; ABI=armeabi-v7a ;;
      android-x86_64) CLANG=x86_64-linux-android$API; CPU_FAMILY=x86_64; CPU=x86_64; FF_ARCH=x86_64; ABI=x86_64 ;;
    esac
    CC=$CLANG-clang; CXX=$CLANG-clang++; AR=llvm-ar; NM=llvm-nm; RANLIB=llvm-ranlib; STRIP=llvm-strip
    SYSTEM=android; FF_OS=android
    EXTRA_CFLAGS="-fPIC"
    ;;
  macos-*|ios-*|iossim-*)
    OS=darwin
    case $TARGET in
      macos-arm64) SDK=macosx; ARCH=arm64; MIN=-mmacosx-version-min=11.0; SUBSYSTEM=macos ;;
      macos-x86_64) SDK=macosx; ARCH=x86_64; MIN=-mmacosx-version-min=11.0; SUBSYSTEM=macos ;;
      ios-arm64) SDK=iphoneos; ARCH=arm64; MIN=-miphoneos-version-min=15.0; SUBSYSTEM=ios ;;
      iossim-arm64) SDK=iphonesimulator; ARCH=arm64; MIN=-mios-simulator-version-min=15.0; SUBSYSTEM=ios-simulator ;;
      iossim-x86_64) SDK=iphonesimulator; ARCH=x86_64; MIN=-mios-simulator-version-min=15.0; SUBSYSTEM=ios-simulator ;;
    esac
    APPLE_FLAGS="-arch $ARCH -isysroot $(xcrun --sdk $SDK --show-sdk-path) $MIN"
    CC="clang $APPLE_FLAGS"; CXX="clang++ $APPLE_FLAGS"; OBJC="clang $APPLE_FLAGS"
    AR=ar; NM=nm; RANLIB=ranlib; STRIP=strip
    SYSTEM=darwin; CPU_FAMILY=$([ $ARCH = arm64 ] && echo aarch64 || echo x86_64); CPU=$ARCH
    FF_OS=darwin; FF_ARCH=$ARCH
    EXTRA_CFLAGS=""
    ;;
  *) echo "unknown target $TARGET"; exit 1 ;;
esac

export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
export PKG_CONFIG_PATH=""

write_cross() {
local file=$1; shift
local flags="$COMMON_CFLAGS $EXTRA_CFLAGS $*"
arr() { printf "["; for w in $1; do printf "'%s', " "$w"; done; printf "]"; }
cat > "$file" <<EOF
[binaries]
c = $(arr "$CC")
cpp = $(arr "$CXX")
$( [ $OS = darwin ] && echo "objc = $(arr "$OBJC")" )
ar = '$AR'
strip = '$STRIP'
nm = '$NM'
pkg-config = 'pkg-config'
$( [ $OS = windows ] && echo "windres = '$HOST-windres'" )

[host_machine]
system = '$SYSTEM'
cpu_family = '$CPU_FAMILY'
cpu = '$CPU'
endian = 'little'
$( [ $OS = darwin ] && echo "subsystem = '$SUBSYSTEM'" )

[built-in options]
c_args = ['-I$PREFIX/include', $(for f in $flags; do printf "'%s', " "$f"; done)]
$( [ $OS = darwin ] && echo "objc_args = ['-I$PREFIX/include', $(for f in $flags; do printf "'%s', " "$f"; done)]" )
cpp_args = ['-I$PREFIX/include', $(for f in $flags; do printf "'%s', " "$f"; done)]
c_link_args = ['-L$PREFIX/lib']
cpp_link_args = ['-L$PREFIX/lib']
EOF
}

# meson_build NAME OPTIMIZATION [meson options...]; OPTIMIZATION z compiles
# with -Oz. EXTRA_FLAGS adds compiler flags for that one project.
meson_build() {
  local name=$1 opt=$2; shift 2
  local dir=$BUILD/$name
  [ -f "$dir/.done" ] && return
  rm -rf "$dir"
  local cross=$BUILD/cross-$name.txt
  if [ "$opt" = z ]; then opt=s; write_cross "$cross" -Oz ${EXTRA_FLAGS:-}; else write_cross "$cross" ${EXTRA_FLAGS:-}; fi
  meson setup "$dir" "$SRC/$name" --cross-file "$cross" --prefix "$PREFIX" --libdir lib \
    --buildtype release -Doptimization="$opt" -Ddefault_library=static -Dprefer_static=true \
    -Db_ndebug=true "$@" > "$dir.log" 2>&1 || { tail -40 "$dir.log"; exit 1; }
  ninja -C "$dir" -j"$JOBS" install >> "$dir.log" 2>&1 || { tail -60 "$dir.log"; exit 1; }
  touch "$dir/.done"
}

# Android has no system TLS for native code; Windows uses Schannel and Apple
# Secure Transport.
if [ $OS = android ] && [ ! -f "$BUILD/mbedtls/.done" ]; then
  rm -rf "$BUILD/mbedtls"
  cmake -S "$SRC/mbedtls" -B "$BUILD/mbedtls" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI=$ABI -DANDROID_PLATFORM=$API \
    -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_C_FLAGS="$COMMON_CFLAGS" \
    -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF -DMBEDTLS_FATAL_WARNINGS=OFF -DUSE_SHARED_MBEDTLS_LIBRARY=OFF \
    > "$BUILD/mbedtls.log" 2>&1 || { tail -40 "$BUILD/mbedtls.log"; exit 1; }
  ninja -C "$BUILD/mbedtls" -j"$JOBS" install >> "$BUILD/mbedtls.log" 2>&1 || { tail -40 "$BUILD/mbedtls.log"; exit 1; }
  touch "$BUILD/mbedtls/.done"
fi

meson_build dav1d 2 -Denable_tools=false -Denable_tests=false -Denable_examples=false
meson_build freetype z -Dbrotli=disabled -Dbzip2=disabled -Dharfbuzz=disabled -Dpng=disabled -Dzlib=disabled -Dtests=disabled
meson_build fribidi z -Ddocs=false -Dbin=false -Dtests=false
# libass only lays out mpv's OSD text here; HB_MINI leaves out AAT and legacy shaping.
EXTRA_FLAGS=-DHB_MINI meson_build harfbuzz z -Dglib=disabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dicu=disabled \
  -Dfreetype=enabled -Dtests=disabled -Ddocs=disabled -Dutilities=disabled -Dintrospection=disabled -Dgdi=disabled -Ddirectwrite=disabled
meson_build libass z -Dfontconfig=disabled -Ddirectwrite=disabled -Dcoretext=disabled -Drequire-system-font-provider=false \
  -Dasm=disabled -Dtest=disabled -Dcompare=disabled -Dprofile=disabled -Dfuzz=disabled -Dcheckasm=disabled -Dlibunibreak=disabled
meson_build libplacebo z -Dvulkan=disabled -Dglslang=disabled -Dshaderc=disabled -Dlcms=disabled -Dlibdovi=disabled \
  -Dd3d11=disabled -Dopengl=enabled -Ddemos=false -Dtests=false -Dxxhash=disabled -Dunwind=disabled

# FFmpeg keeps the codecs, containers and protocols booru posts use: H.264,
# HEVC, VP8, VP9, AV1 and MPEG-4 video, the common audio codecs, MP4 and
# Matroska/WebM, and HTTP(S) with an HTTP proxy.
if [ ! -f "$BUILD/ffmpeg/.done" ]; then
  rm -rf "$BUILD/ffmpeg"; mkdir -p "$BUILD/ffmpeg"
  DECODERS="h264 hevc vp8 vp9 av1 libdav1d mpeg4 aac aac_latm mp3 mp3float opus vorbis flac alac pcm_s16le pcm_s24le pcm_f32le"
  HWACCELS=""
  if [ $OS = windows ]; then
    for c in h264 hevc vp9 av1; do HWACCELS="$HWACCELS ${c}_d3d11va ${c}_d3d11va2 ${c}_dxva2"; done
    PLATFORM_FLAGS="--enable-d3d11va --enable-dxva2 --enable-schannel"
  elif [ $OS = darwin ]; then
    for c in h264 hevc vp9 av1 mpeg4; do HWACCELS="$HWACCELS ${c}_videotoolbox"; done
    PLATFORM_FLAGS="--enable-videotoolbox --enable-securetransport --enable-zlib"
  else
    DECODERS="$DECODERS h264_mediacodec hevc_mediacodec vp8_mediacodec vp9_mediacodec av1_mediacodec mpeg4_mediacodec"
    # mbedTLS is Apache-2.0, which makes this FFmpeg LGPL v3.
    PLATFORM_FLAGS="--enable-jni --enable-mediacodec --enable-mbedtls --enable-version3 --enable-zlib"
  fi
  list() { local kind=$1; shift; for x in "$@"; do printf -- "--enable-%s=%s " "$kind" "$x"; done; }
  # shellcheck disable=SC2046,SC2086
  (cd "$BUILD/ffmpeg" && "$SRC/ffmpeg/configure" --prefix="$PREFIX" --enable-cross-compile --target-os=$FF_OS --arch=$FF_ARCH \
    --cc="$CC" --cxx="$CXX" --ar="$AR" --nm="$NM" --ranlib="$RANLIB" --strip="$STRIP" \
    --pkg-config=pkg-config --pkg-config-flags=--static \
    --extra-cflags="-I$PREFIX/include $COMMON_CFLAGS $EXTRA_CFLAGS" --extra-ldflags="-L$PREFIX/lib" \
    --enable-static --disable-shared --enable-pic --disable-debug --enable-small \
    --disable-programs --disable-doc --disable-avdevice --disable-autodetect --disable-everything \
    --enable-avcodec --enable-avformat --enable-avfilter --enable-swscale --enable-swresample \
    --enable-network --enable-libdav1d $PLATFORM_FLAGS \
    $(list decoder $DECODERS) $(list hwaccel $HWACCELS) \
    $(list demuxer mov matroska) \
    $(list parser h264 hevc vp8 vp9 av1 aac mpegaudio opus vorbis flac mpeg4video) \
    $(list protocol file http https tcp tls httpproxy udp) \
    $(list filter aformat aresample anull format null scale) > "$BUILD/ffmpeg.log" 2>&1 &&
    make -j"$JOBS" install >> "$BUILD/ffmpeg.log" 2>&1) || { tail -60 "$BUILD/ffmpeg.log"; exit 1; }
  touch "$BUILD/ffmpeg/.done"
fi

MPV_COMMON="-Dgpl=false -Dlibmpv=true -Dcplayer=false -Dtests=false -Dfuzzers=false -Dcplugins=disabled
  -Dlua=disabled -Djavascript=disabled -Dlibarchive=disabled -Dlibbluray=disabled -Ddvdnav=disabled -Dcdda=disabled
  -Duchardet=disabled -Drubberband=disabled -Dlcms2=disabled -Dzimg=disabled -Djpeg=disabled -Dvapoursynth=disabled
  -Dvulkan=disabled -Dshaderc=disabled -Dspirv-cross=disabled -Diconv=disabled -Dzlib=disabled
  -Dmanpage-build=disabled -Dhtml-build=disabled -Dpdf-build=disabled"
if [ $OS = windows ]; then
  MPV_LIB=shared
  MPV_PLATFORM="-Dgl-win32=enabled -Degl-angle=enabled -Dd3d-hwaccel=enabled -Dd3d11=disabled
    -Dc_link_args=['-L$PREFIX/lib','-static','-Wl,--gc-sections','-Wl,--icf=all','-lc++']"
elif [ $OS = darwin ]; then
  MPV_LIB=static
  MPV_PLATFORM="-Dplain-gl=enabled -Dswift-build=disabled -Dcocoa=disabled -Dmacos-cocoa-cb=disabled
    -Dmacos-media-player=disabled -Dmacos-touchbar=disabled -Davfoundation=disabled -Dvideotoolbox-pl=disabled"
  if [ $SUBSYSTEM = macos ]; then
    MPV_PLATFORM="$MPV_PLATFORM -Dvideotoolbox-gl=enabled -Dcoreaudio=enabled"
  else
    MPV_PLATFORM="$MPV_PLATFORM -Dcoreaudio=disabled -Daudiounit=enabled -Dios-gl=enabled -Dvideotoolbox-gl=disabled"
  fi
else
  MPV_LIB=static
  MPV_PLATFORM="-Degl-android=enabled -Dandroid-media-ndk=enabled -Daudiotrack=enabled -Dopensles=enabled"
fi
if [ ! -f "$BUILD/mpv/.done" ]; then
  rm -rf "$BUILD/mpv"
  write_cross "$BUILD/cross-mpv.txt" -Oz
  # shellcheck disable=SC2086
  meson setup "$BUILD/mpv" "$SRC/mpv" --cross-file "$BUILD/cross-mpv.txt" --prefix "$PREFIX" --libdir lib \
    --buildtype release -Doptimization=s -Ddefault_library=$MPV_LIB -Dprefer_static=true -Db_ndebug=true \
    $MPV_COMMON $MPV_PLATFORM > "$BUILD/mpv.log" 2>&1 || { tail -60 "$BUILD/mpv.log"; exit 1; }
  ninja -C "$BUILD/mpv" -j"$JOBS" install >> "$BUILD/mpv.log" 2>&1 || { tail -60 "$BUILD/mpv.log"; exit 1; }
  touch "$BUILD/mpv/.done"
fi

rm -rf "$OUT"; mkdir -p "$OUT"
if [ $OS = windows ]; then
  cp "$PREFIX/bin/libmpv-2.dll" "$OUT/"
  "$STRIP" "$OUT/libmpv-2.dll"
elif [ $OS = darwin ]; then
  # One binary per slice; package() joins them into Mpv.xcframework.
  if [ $SUBSYSTEM = macos ]; then NAME=@rpath/Mpv.framework/Versions/A/Mpv; else NAME=@rpath/Mpv.framework/Mpv; fi
  # shellcheck disable=SC2046
  $CXX -dynamiclib -o "$OUT/Mpv" -install_name "$NAME" -Wl,-dead_strip -Wl,-exported_symbol,'_mpv_*' \
    -Wl,-force_load,"$PREFIX/lib/libmpv.a" \
    $(pkg-config --static --libs mpv | sed 's/-lmpv / /') \
    $([ $SUBSYSTEM = macos ] || echo -framework OpenGLES -framework AVFoundation -framework Foundation)
  strip -x "$OUT/Mpv"
else
  # media_kit hands libmpv.so the JavaVM through mpv_lavc_set_java_vm.
  cat > "$BUILD/jni_vm.c" <<'EOF'
#include <libavcodec/jni.h>
__attribute__((visibility("default"))) int mpv_lavc_set_java_vm(void *vm) { return av_jni_set_java_vm(vm, 0); }
EOF
  printf '{ global: mpv_*; av_jni_*; local: *; };\n' > "$BUILD/libmpv.map"
  # --no-undefined: Android's loader rejects a library with unresolved symbols at
  # load time, so a missing dependency must fail here instead.
  # shellcheck disable=SC2046
  "$CXX" -shared -o "$OUT/libmpv.so" -Wl,-soname,libmpv.so -Wl,--gc-sections -Wl,--pack-dyn-relocs=android \
    -Wl,--icf=all -Wl,--no-undefined -Wl,--version-script,"$BUILD/libmpv.map" \
    -I"$PREFIX/include" -x c "$BUILD/jni_vm.c" -x none \
    -Wl,--whole-archive "$PREFIX/lib/libmpv.a" -Wl,--no-whole-archive \
    $(pkg-config --static --libs-only-L --libs-only-l mpv | sed 's/-lmpv / /') -static-libstdc++ \
    -landroid -lEGL -lOpenSLES -lmediandk -llog -lz -lm -ldl
  "$STRIP" --strip-unneeded "$OUT/libmpv.so"
fi
}

framework_plist() { # framework_plist FILE PLATFORM MINIMUM_KEY MINIMUM
  cat > "$1" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Mpv</string>
  <key>CFBundleIdentifier</key><string>io.github.normalllll.booruflow.Mpv</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Mpv</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>0.42.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleSupportedPlatforms</key><array><string>$2</string></array>
  <key>$3</key><string>$4</string>
</dict>
</plist>
EOF
}

# Writes the release archives and their checksums to $WORK/dist.
package() {
  local out=$WORK/out dist=$WORK/dist stage=$WORK/stage
  rm -rf "$dist" "$stage"; mkdir -p "$dist" "$stage"

  (cd "$out/windows-x86_64" && zip -qX "$dist/libmpv-windows-x86_64.zip" libmpv-2.dll)

  for abi in arm64-v8a armeabi-v7a x86_64; do
    mkdir -p "$stage/android/$abi"
    cp "$out/android-$abi/libmpv.so" "$stage/android/$abi/"
  done
  (cd "$stage/android" && zip -qrX "$dist/libmpv-android.zip" .)

  local mac=$stage/macos/Mpv.framework
  mkdir -p "$mac/Versions/A/Resources" "$stage/ios/Mpv.framework" "$stage/iossim/Mpv.framework"
  lipo -create "$out/macos-arm64/Mpv" "$out/macos-x86_64/Mpv" -output "$mac/Versions/A/Mpv"
  framework_plist "$mac/Versions/A/Resources/Info.plist" MacOSX LSMinimumSystemVersion 11.0
  ln -s A "$mac/Versions/Current"
  ln -s Versions/Current/Mpv "$mac/Mpv"
  ln -s Versions/Current/Resources "$mac/Resources"
  cp "$out/ios-arm64/Mpv" "$stage/ios/Mpv.framework/Mpv"
  framework_plist "$stage/ios/Mpv.framework/Info.plist" iPhoneOS MinimumOSVersion 15.0
  lipo -create "$out/iossim-arm64/Mpv" "$out/iossim-x86_64/Mpv" -output "$stage/iossim/Mpv.framework/Mpv"
  framework_plist "$stage/iossim/Mpv.framework/Info.plist" iPhoneSimulator MinimumOSVersion 15.0
  xcodebuild -create-xcframework -output "$stage/Mpv.xcframework" \
    -framework "$mac" -framework "$stage/ios/Mpv.framework" -framework "$stage/iossim/Mpv.framework" > /dev/null
  # zip -y keeps the macOS framework's symlinks.
  (cd "$stage" && zip -qryX "$dist/Mpv.xcframework.zip" Mpv.xcframework)

  rm -rf "$stage"
  (cd "$dist" && shasum -a 256 ./*.zip | sed 's# \./# #' > SHA256SUMS && cat SHA256SUMS)
}

if [ $# -eq 0 ]; then
  for target in $ALL_TARGETS; do (build_target "$target"); done
  package
else
  for target in "$@"; do (build_target "$target"); done
fi
