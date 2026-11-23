# Fetches Mpv.xcframework from the release that tool/libmpv/build.sh produced.
# media_kit_video finds the framework through Frameworks/.symlinks/mpv/<platform>.

LIBMPV_URL=https://github.com/normalllll/BooruFlow/releases/download/libmpv-0.42.0-1/Mpv.xcframework.zip
LIBMPV_SHA256=955f89d66486d20b842d8cf4f6d9313a042f2c95560a2df422cca1703cbb78ae

all: Frameworks/.symlinks

.cache/$(LIBMPV_SHA256).zip:
	mkdir -p .cache
	rm -f .cache/*.zip .cache/*.tmp
	curl -sSfL $(LIBMPV_URL) -o .cache/download.tmp
	echo "$(LIBMPV_SHA256)  .cache/download.tmp" | shasum -a 256 -c -
	mv .cache/download.tmp $@

Frameworks/.symlinks: .cache/$(LIBMPV_SHA256).zip
	rm -rf Frameworks
	mkdir -p Frameworks/.symlinks/mpv
	unzip -q .cache/$(LIBMPV_SHA256).zip -d Frameworks
	sed -i '' 's/\r$$//g' create_framework_symlinks.sh
	sh create_framework_symlinks.sh Frameworks/Mpv.xcframework Frameworks/.symlinks/mpv

.PHONY: all clean
clean:
	rm -rf .cache Frameworks
