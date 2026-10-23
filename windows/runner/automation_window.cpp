#include "automation_window.h"
#include <flutter_windows.h>
#include <algorithm>
#include <cmath>
#include <optional>
#include <string>
#include <vector>
namespace {
struct Monitor {
  HMONITOR handle;
  MONITORINFO info;
};

BOOL CALLBACK CollectMonitor(HMONITOR handle, HDC, LPRECT, LPARAM data) {
  auto* monitors = reinterpret_cast<std::vector<Monitor>*>(data);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  if (GetMonitorInfo(handle, &info)) monitors->push_back({handle, info});
  return TRUE;
}

Monitor SelectMonitor() {
  std::vector<Monitor> monitors;
  EnumDisplayMonitors(nullptr, nullptr, CollectMonitor,
                      reinterpret_cast<LPARAM>(&monitors));
  wchar_t setting[32]{};
  GetEnvironmentVariableW(L"BOORUFLOW_AUTOMATION_PLACEMENT", setting, 32);
  const bool primary_only = std::wstring(setting) == L"primary";
  Monitor selected{MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY), {}};
  selected.info.cbSize = sizeof(selected.info);
  GetMonitorInfo(selected.handle, &selected.info);
  LONG largest_secondary = 0;
  for (const auto& monitor : monitors) {
    if (primary_only || (monitor.info.dwFlags & MONITORINFOF_PRIMARY)) continue;
    const auto& work = monitor.info.rcWork;
    const LONG area = (work.right - work.left) * (work.bottom - work.top);
    if (area > largest_secondary) {
      largest_secondary = area;
      selected = monitor;
    }
  }
  return selected;
}
}  // namespace

AutomationPlacement GetAutomationPlacement() {
  const auto monitor = SelectMonitor();
  const auto& work = monitor.info.rcWork;
  const double scale = FlutterDesktopGetDpiForMonitor(monitor.handle) / 96.0;
  const int margin = static_cast<int>(24 * scale);
  const int width = std::min(1280, std::max(320, static_cast<int>((work.right - work.left - margin * 2) / scale)));
  const int height = std::min(800, std::max(480, static_cast<int>((work.bottom - work.top - margin * 2) / scale)));
  return {work.left + (work.right - work.left - static_cast<int>(width * scale)) / 2,
          work.top + (work.bottom - work.top - static_cast<int>(height * scale)) / 2,
          width, height};
}
AutomationWindow::AutomationWindow(flutter::BinaryMessenger* messenger, HWND window,
                                   std::function<void()> redraw)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "booruflow/automation",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this, redraw](const auto& call, auto result) {
    if (call.method_name() == "present") {
      redraw();
      RedrawWindow(window_, nullptr, nullptr, RDW_INVALIDATE | RDW_ALLCHILDREN);
      result->Success(); return;
    }
    if (call.method_name() == "close") {
      result->Success();
      PostMessage(window_, WM_CLOSE, 0, 0);
      return;
    }
    if (call.method_name() == "resize") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!args) { result->Error("arguments", "Expected width and height"); return; }
      auto number = [&](const char* key) -> std::optional<double> {
        const auto found = args->find(flutter::EncodableValue(key));
        if (found == args->end()) return std::nullopt;
        if (const auto* value = std::get_if<double>(&found->second)) return *value;
        if (const auto* value = std::get_if<int32_t>(&found->second)) return *value;
        if (const auto* value = std::get_if<int64_t>(&found->second)) return static_cast<double>(*value);
        return std::nullopt;
      };
      const auto requested_width = number("width"), requested_height = number("height");
      if (!requested_width || !requested_height ||
          !std::isfinite(*requested_width) || !std::isfinite(*requested_height) ||
          *requested_width < 320 || *requested_height < 480) {
        result->Error("size", "Minimum test window size is 320 x 480"); return;
      }
      const double scale = GetDpiForWindow(window_) / 96.0;
      MONITORINFO monitor{}; monitor.cbSize = sizeof(monitor);
      GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST), &monitor);
      RECT bounds{}; GetWindowRect(window_, &bounds);
      RECT client{}; GetClientRect(window_, &client);
      const auto& work = monitor.rcWork;
      // RPC sizes refer to Flutter's client viewport, not the outer DWM frame.
      // Measure the actual custom frame instead of assuming Win32 caption sizes.
      const int frame_width = (bounds.right - bounds.left) - (client.right - client.left);
      const int frame_height = (bounds.bottom - bounds.top) - (client.bottom - client.top);
      const int width = std::min(static_cast<int>(std::lround(*requested_width * scale)) + frame_width,
                                 static_cast<int>(work.right - work.left));
      const int height = std::min(static_cast<int>(std::lround(*requested_height * scale)) + frame_height,
                                  static_cast<int>(work.bottom - work.top));
      const int x = std::clamp(static_cast<int>(bounds.left), static_cast<int>(work.left),
                               static_cast<int>(work.right) - width);
      const int y = std::clamp(static_cast<int>(bounds.top), static_cast<int>(work.top),
                               static_cast<int>(work.bottom) - height);
      SetWindowPos(window_, nullptr, x, y, width, height, SWP_NOZORDER | SWP_NOACTIVATE);
      result->Success(); return;
    }
    if (call.method_name() != "status") { result->NotImplemented(); return; }
    const HWND foreground = GetForegroundWindow();
    const HWND focus = GetFocus();
    POINT cursor{};
    GetCursorPos(&cursor);
    RECT bounds{};
    GetWindowRect(window_, &bounds);
    bool below_foreground = false;
    for (HWND above = GetWindow(window_, GW_HWNDPREV); above;
         above = GetWindow(above, GW_HWNDPREV)) {
      if (above == foreground) { below_foreground = true; break; }
    }
    MONITORINFO monitor{};
    monitor.cbSize = sizeof(monitor);
    GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST), &monitor);
    int monitor_count = 0;
    EnumDisplayMonitors(nullptr, nullptr,
      [](HMONITOR, HDC, LPRECT, LPARAM data) -> BOOL {
        ++*reinterpret_cast<int*>(data); return TRUE;
      }, reinterpret_cast<LPARAM>(&monitor_count));
    auto rect_map = [](const RECT& rect) {
      flutter::EncodableMap map;
      map[flutter::EncodableValue("left")] = flutter::EncodableValue(static_cast<int64_t>(rect.left));
      map[flutter::EncodableValue("top")] = flutter::EncodableValue(static_cast<int64_t>(rect.top));
      map[flutter::EncodableValue("right")] = flutter::EncodableValue(static_cast<int64_t>(rect.right));
      map[flutter::EncodableValue("bottom")] = flutter::EncodableValue(static_cast<int64_t>(rect.bottom));
      return flutter::EncodableValue(map);
    };
    flutter::EncodableMap status;
    status[flutter::EncodableValue("hwnd")] = flutter::EncodableValue(static_cast<int64_t>(reinterpret_cast<intptr_t>(window_)));
    status[flutter::EncodableValue("pid")] = flutter::EncodableValue(static_cast<int64_t>(GetCurrentProcessId()));
    status[flutter::EncodableValue("foregroundHwnd")] = flutter::EncodableValue(static_cast<int64_t>(reinterpret_cast<intptr_t>(foreground)));
    status[flutter::EncodableValue("isForeground")] = flutter::EncodableValue(foreground == window_);
    status[flutter::EncodableValue("hasNativeFocus")] = flutter::EncodableValue(focus == window_ || (focus != nullptr && IsChild(window_, focus)));
    status[flutter::EncodableValue("activationCount")] = flutter::EncodableValue(activation_count_);
    status[flutter::EncodableValue("isBelowForeground")] = flutter::EncodableValue(below_foreground);
    status[flutter::EncodableValue("topmost")] = flutter::EncodableValue((GetWindowLongPtr(window_, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0);
    status[flutter::EncodableValue("monitorPrimary")] = flutter::EncodableValue((monitor.dwFlags & MONITORINFOF_PRIMARY) != 0);
    status[flutter::EncodableValue("monitorCount")] = flutter::EncodableValue(monitor_count);
    status[flutter::EncodableValue("windowBounds")] = rect_map(bounds);
    status[flutter::EncodableValue("monitorWorkArea")] = rect_map(monitor.rcWork);
    status[flutter::EncodableValue("cursorX")] = flutter::EncodableValue(static_cast<int64_t>(cursor.x));
    status[flutter::EncodableValue("cursorY")] = flutter::EncodableValue(static_cast<int64_t>(cursor.y));
    status[flutter::EncodableValue("visible")] = flutter::EncodableValue(IsWindowVisible(window_) != FALSE);
    status[flutter::EncodableValue("minimized")] = flutter::EncodableValue(IsIconic(window_) != FALSE);
    result->Success(flutter::EncodableValue(status));
  });
}
