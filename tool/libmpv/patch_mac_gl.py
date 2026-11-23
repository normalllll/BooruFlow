"""Lets libmpv use VideoToolbox's OpenGL interop on macOS without the Cocoa
backend. The interop only needs a current CGL context, which the embedding
app provides through the render API; Cocoa itself requires Swift and Metal."""
import sys

path = sys.argv[1]
src = open(path).read()
if 'plain-gl VideoToolbox interop' in src:
    sys.exit(0)

old = '''videotoolbox_gl = get_option('videotoolbox-gl').require(
    features['gl-cocoa'] or features['ios-gl'],
    error_message: 'gl-cocoa nor ios-gl could be found!',
)
features += {'videotoolbox-gl': videotoolbox_gl.allowed()}
'''
new = '''# plain-gl VideoToolbox interop: CGL only, no Cocoa.
mac_plain_gl = (darwin and not features['ios-gl'] and plain_gl.allowed() and
                GL.found() and cc.has_header('OpenGL/OpenGL.h'))
videotoolbox_gl = get_option('videotoolbox-gl').require(
    features['gl-cocoa'] or features['ios-gl'] or mac_plain_gl,
    error_message: 'gl-cocoa nor ios-gl could be found!',
)
features += {'videotoolbox-gl': videotoolbox_gl.allowed()}
if features['videotoolbox-gl'] and mac_plain_gl and not features['gl-cocoa']
    dependencies += [GL, dependency('appleframeworks', modules: 'IOSurface')]
endif
# CoreAudio's string helpers otherwise come with the Cocoa sources.
if darwin and features['coreaudio'] and not features['cocoa']
    sources += files('osdep/utils-mac.c')
endif
'''
if src.count(old) != 1:
    sys.exit('patch_mac_gl: videotoolbox-gl block not found')
open(path, 'w').write(src.replace(old, new))
