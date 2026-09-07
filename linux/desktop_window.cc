#include "desktop_window.h"

#include <cstring>

namespace {
struct DesktopWindow {
  GtkWindow* window;
  GtkHeaderBar* header;
  GtkWidget* sidebar;
  FlMethodChannel* channel;
  gint64 revision = 0;

  ~DesktopWindow() {
    fl_method_channel_set_method_call_handler(channel, nullptr, nullptr, nullptr);
    g_clear_object(&channel);
  }
};

FlValue* window_state(DesktopWindow* self) {
  FlValue* value = fl_value_new_map();
  GdkWindow* surface = gtk_widget_get_window(GTK_WIDGET(self->window));
  const bool fullscreen = surface != nullptr &&
      (gdk_window_get_state(surface) & GDK_WINDOW_STATE_FULLSCREEN) != 0;
  fl_value_set_string_take(value, "maximized",
                           fl_value_new_bool(gtk_window_is_maximized(self->window)));
  fl_value_set_string_take(value, "active",
                           fl_value_new_bool(gtk_window_is_active(self->window)));
  fl_value_set_string_take(value, "fullscreen", fl_value_new_bool(fullscreen));
  fl_value_set_string_take(value, "revision", fl_value_new_int(self->revision));
  return value;
}

void publish_state(DesktopWindow* self) {
  ++self->revision;
  g_autoptr(FlValue) state = window_state(self);
  fl_method_channel_invoke_method(self->channel, "stateChanged", state,
                                  nullptr, nullptr, nullptr);
}

gboolean state_changed(GtkWidget*, GdkEventWindowState*, gpointer data) {
  publish_state(static_cast<DesktopWindow*>(data));
  return FALSE;
}

void active_changed(GObject*, GParamSpec*, gpointer data) {
  publish_state(static_cast<DesktopWindow*>(data));
}

void sidebar_clicked(GtkButton*, gpointer data) {
  auto* self = static_cast<DesktopWindow*>(data);
  fl_method_channel_invoke_method(self->channel, "toggleSidebar", nullptr,
                                  nullptr, nullptr, nullptr);
}

bool bool_value(FlValue* map, const char* key) {
  FlValue* value = fl_value_lookup_string(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
         fl_value_get_bool(value);
}

const char* string_value(FlValue* map, const char* key) {
  FlValue* value = fl_value_lookup_string(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value) : "";
}

void method_call(FlMethodChannel*, FlMethodCall* call, gpointer data) {
  auto* self = static_cast<DesktopWindow*>(data);
  const char* method = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, "getState") == 0) {
    g_autoptr(FlValue) state = window_state(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(state));
  } else if (strcmp(method, "setToolbar") == 0) {
    FlValue* config = fl_method_call_get_args(call);
    if (config != nullptr && fl_value_get_type(config) == FL_VALUE_TYPE_MAP) {
      const char* title = string_value(config, "title");
      gtk_window_set_title(self->window, title);
      gtk_header_bar_set_title(self->header, title);
      gtk_widget_set_visible(self->sidebar, bool_value(config, "showSidebarButton"));
      gtk_widget_set_tooltip_text(self->sidebar, string_value(config, "sidebarTooltip"));
      AtkObject* accessible = gtk_widget_get_accessible(self->sidebar);
      atk_object_set_name(accessible, string_value(config, "sidebarTooltip"));
      g_object_set(gtk_widget_get_settings(GTK_WIDGET(self->window)),
                   "gtk-application-prefer-dark-theme", bool_value(config, "dark"),
                   nullptr);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setRegions") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "toggleMaximized") == 0) {
    if (gtk_window_is_maximized(self->window)) {
      gtk_window_unmaximize(self->window);
    } else {
      gtk_window_maximize(self->window);
    }
    // The window manager decides when/if this succeeds. Publish its actual
    // state via window-state-event instead of returning a requested state.
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "minimize") == 0) {
    gtk_window_iconify(self->window);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "close") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    g_idle_add([](gpointer window) -> gboolean {
      gtk_window_close(GTK_WINDOW(window));
      g_object_unref(window);
      return G_SOURCE_REMOVE;
    }, g_object_ref(self->window));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Desktop window response failed: %s", error->message);
  }
}
}  // namespace

void configure_desktop_window(GtkWindow* window, FlEngine* engine) {
  // Supplying GtkHeaderBar keeps GTK's client-side resize frame and native
  // event handling, including Wayland input serials and desktop preferences.
  gtk_window_set_decorated(window, TRUE);
  GtkWidget* header = gtk_header_bar_new();
  gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(header), TRUE);
  gtk_header_bar_set_title(GTK_HEADER_BAR(header), gtk_window_get_title(window));
  GtkWidget* sidebar = gtk_button_new_from_icon_name("sidebar-show-symbolic", GTK_ICON_SIZE_BUTTON);
  gtk_widget_set_no_show_all(sidebar, TRUE);
  gtk_header_bar_pack_start(GTK_HEADER_BAR(header), sidebar);
  gtk_widget_show(header);
  gtk_window_set_titlebar(window, header);
  gtk_widget_set_size_request(GTK_WIDGET(window), 480, 360);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine), "desktop_window", FL_METHOD_CODEC(codec));
  auto* self = new DesktopWindow{window, GTK_HEADER_BAR(header), sidebar, channel};
  fl_method_channel_set_method_call_handler(channel, method_call, self, nullptr);
  g_signal_connect(window, "window-state-event", G_CALLBACK(state_changed), self);
  g_signal_connect(window, "notify::is-active", G_CALLBACK(active_changed), self);
  g_signal_connect(sidebar, "clicked", G_CALLBACK(sidebar_clicked), self);
  g_object_set_data_full(G_OBJECT(window), "desktop-window", self,
                         [](gpointer data) { delete static_cast<DesktopWindow*>(data); });
  g_signal_connect(window, "destroy", G_CALLBACK(+[](GtkWidget*, gpointer data) {
    auto* bridge = static_cast<DesktopWindow*>(data);
    fl_method_channel_set_method_call_handler(bridge->channel, nullptr, nullptr, nullptr);
  }), self);
}
