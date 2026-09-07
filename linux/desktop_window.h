#ifndef RUNNER_DESKTOP_WINDOW_H_
#define RUNNER_DESKTOP_WINDOW_H_

#include <flutter_linux/flutter_linux.h>

// GTK owns the title bar, resize borders, window menu and button placement.
// The bridge adds application actions without replacing those native behaviors.
void configure_desktop_window(GtkWindow* window, FlEngine* engine);

#endif
