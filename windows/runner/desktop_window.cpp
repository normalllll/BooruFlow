#include "desktop_window.h"

#include <dwmapi.h>
#include <shellapi.h>
#include <windowsx.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <string>
#include <variant>

namespace {
constexpr UINT_PTR kWindowSubclass = 1;
constexpr UINT_PTR kContentSubclass = 2;

double Number(const flutter::EncodableValue& value) {
  if (const auto* number = std::get_if<double>(&value)) return *number;
  if (const auto* number = std::get_if<int32_t>(&value)) return *number;
  return 0;
}

POINT CursorPosition() {
  POINT point{};
  GetCursorPos(&point);
  return point;
}

const char* ButtonName(int hit) {
  return hit == HTMAXBUTTON ? "maximize" : "";
}
}  // namespace

DesktopWindow::DesktopWindow(HWND window, HWND content,
                             flutter::BinaryMessenger* messenger)
    : window_(window), content_(content) {
  SetWindowSubclass(window_, WindowProc, kWindowSubclass,
                    reinterpret_cast<DWORD_PTR>(this));
  SetWindowSubclass(content_, ContentProc, kContentSubclass,
                    reinterpret_cast<DWORD_PTR>(this));

  // Keep the standard window capabilities. Only the non-client layout is
  // replaced; system commands, taskbar operations and keyboard snapping remain.
  SetWindowLongPtr(window_, GWL_STYLE,
                   GetWindowLongPtr(window_, GWL_STYLE) | WS_OVERLAPPEDWINDOW);
  SetWindowPos(window_, nullptr, 0, 0, 0, 0,
               SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                   SWP_NOACTIVATE);

  const DWM_WINDOW_CORNER_PREFERENCE corners = DWMWCP_ROUND;
  DwmSetWindowAttribute(window_, DWMWA_WINDOW_CORNER_PREFERENCE,
                        &corners, sizeof(corners));
  const DWMNCRENDERINGPOLICY rendering = DWMNCRP_ENABLED;
  DwmSetWindowAttribute(window_, DWMWA_NCRENDERING_POLICY,
                        &rendering, sizeof(rendering));

  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "desktop_window",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();
        if (method == "getState") {
          result->Success(State());
          return;
        }
        if (method == "setRegions") {
          UpdateRegions(call.arguments());
        } else if (method == "setToolbar") {
          // The Windows toolbar is rendered by Flutter.
        } else if (method == "minimize") {
          PostMessage(window_, WM_SYSCOMMAND, SC_MINIMIZE, 0);
        } else if (method == "toggleMaximized") {
          PostMessage(window_, WM_SYSCOMMAND,
                       IsZoomed(window_) ? SC_RESTORE : SC_MAXIMIZE, 0);
        } else if (method == "close") {
          PostMessage(window_, WM_CLOSE, 0, 0);
        } else {
          result->NotImplemented();
          return;
        }
        result->Success();
      });
}

DesktopWindow::~DesktopWindow() {
  channel_->SetMethodCallHandler(nullptr);
  if (IsWindow(content_)) {
    RemoveWindowSubclass(content_, ContentProc, kContentSubclass);
  }
  if (IsWindow(window_)) {
    RemoveWindowSubclass(window_, WindowProc, kWindowSubclass);
  }
}

void DesktopWindow::UpdateRegions(const flutter::EncodableValue* arguments) {
  const auto* list = arguments == nullptr
                         ? nullptr
                         : std::get_if<flutter::EncodableList>(arguments);
  regions_.clear();
  if (list == nullptr) return;
  for (const auto& value : *list) {
    const auto* row = std::get_if<flutter::EncodableList>(&value);
    if (row == nullptr || row->size() != 5) continue;
    const auto* kind = std::get_if<std::string>(&(*row)[4]);
    if (kind == nullptr || (*kind != "caption" && *kind != "maximize")) {
      continue;
    }
    Region region{Number((*row)[0]), Number((*row)[1]), Number((*row)[2]),
                  Number((*row)[3]),
                  *kind == "maximize" ? HTMAXBUTTON : HTCAPTION};
    if (std::isfinite(region.left) && std::isfinite(region.top) &&
        std::isfinite(region.right) && std::isfinite(region.bottom) &&
        region.right > region.left && region.bottom > region.top) {
      regions_.push_back(region);
    }
  }
}

int DesktopWindow::HitTest(POINT point) const {
  RECT rect{};
  GetWindowRect(window_, &rect);
  const UINT dpi = GetDpiForWindow(window_);
  if (!IsZoomed(window_) && !IsIconic(window_)) {
    const int x = GetSystemMetricsForDpi(SM_CXSIZEFRAME, dpi) +
                  GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
    const int y = GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi) +
                  GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
    const bool left = point.x < rect.left + x;
    const bool right = point.x >= rect.right - x;
    const bool top = point.y < rect.top + y;
    const bool bottom = point.y >= rect.bottom - y;
    if (top && left) return HTTOPLEFT;
    if (top && right) return HTTOPRIGHT;
    if (bottom && left) return HTBOTTOMLEFT;
    if (bottom && right) return HTBOTTOMRIGHT;
    if (left) return HTLEFT;
    if (right) return HTRIGHT;
    if (top) return HTTOP;
    if (bottom) return HTBOTTOM;
  }

  ScreenToClient(content_, &point);
  const double scale = dpi / 96.0;
  const double x = point.x / scale;
  const double y = point.y / scale;
  for (const auto& region : regions_) {
    if (x >= region.left && x < region.right && y >= region.top &&
        y < region.bottom) {
      return region.hit;
    }
  }
  return HTCLIENT;
}

flutter::EncodableValue DesktopWindow::State() const {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("maximized"),
       flutter::EncodableValue(IsZoomed(window_) != FALSE)},
      {flutter::EncodableValue("active"),
       flutter::EncodableValue(GetForegroundWindow() == window_)},
      {flutter::EncodableValue("fullscreen"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("hoveredButton"),
       flutter::EncodableValue(ButtonName(hovered_button_))},
      {flutter::EncodableValue("pressedButton"),
       flutter::EncodableValue(ButtonName(pressed_button_))},
      {flutter::EncodableValue("revision"), flutter::EncodableValue(revision_)},
  });
}

void DesktopWindow::PublishState() {
  if (!channel_) return;
  ++revision_;
  channel_->InvokeMethod("stateChanged",
                         std::make_unique<flutter::EncodableValue>(State()));
}

void DesktopWindow::SetHover(int hit) {
  const int button = hit == HTMAXBUTTON ? hit : HTNOWHERE;
  if (hovered_button_ == button) return;
  hovered_button_ = button;
  PublishState();
}

void DesktopWindow::CancelButtonPress() {
  if (pressed_button_ == HTNOWHERE) return;
  pressed_button_ = HTNOWHERE;
  if (GetCapture() == window_) ReleaseCapture();
  PublishState();
}

void DesktopWindow::SetMaximizedClientRect(RECT* rect) const {
  MONITORINFO info{sizeof(MONITORINFO)};
  if (!GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST),
                       &info)) {
    return;
  }
  *rect = info.rcWork;
  // Leave room for the auto-hidden taskbar to reveal on any monitor edge.
  for (UINT edge : {ABE_LEFT, ABE_TOP, ABE_RIGHT, ABE_BOTTOM}) {
    APPBARDATA bar{sizeof(APPBARDATA)};
    bar.uEdge = edge;
    bar.rc = info.rcMonitor;
    if (SHAppBarMessage(ABM_GETAUTOHIDEBAREX, &bar) == 0) continue;
    if (edge == ABE_LEFT && rect->left == info.rcMonitor.left) rect->left += 2;
    if (edge == ABE_TOP && rect->top == info.rcMonitor.top) rect->top += 2;
    if (edge == ABE_RIGHT && rect->right == info.rcMonitor.right) rect->right -= 2;
    if (edge == ABE_BOTTOM && rect->bottom == info.rcMonitor.bottom) rect->bottom -= 2;
  }
}

LRESULT DesktopWindow::HandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                                     LPARAM lparam) {
  switch (message) {
    case WM_NCCALCSIZE:
      if (wparam) {
        if (IsZoomed(hwnd)) {
          SetMaximizedClientRect(
              &reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam)->rgrc[0]);
        }
        return 0;
      }
      break;
    case WM_GETMINMAXINFO: {
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      const double scale = GetDpiForWindow(hwnd) / 96.0;
      info->ptMinTrackSize = {static_cast<LONG>(480 * scale),
                              static_cast<LONG>(360 * scale)};
      return 0;
    }
    case WM_NCHITTEST:
      return HitTest({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
    case WM_NCMOUSEMOVE: {
      SetHover(static_cast<int>(wparam));
      if (!tracking_leave_) {
        TRACKMOUSEEVENT event{sizeof(TRACKMOUSEEVENT),
                              TME_LEAVE | TME_NONCLIENT, hwnd, 0};
        tracking_leave_ = TrackMouseEvent(&event) != FALSE;
      }
      // DWM receives HTMAXBUTTON so Windows 11 can show its Snap Layouts menu.
      LRESULT result = 0;
      if (DwmDefWindowProc(hwnd, message, wparam, lparam, &result)) return result;
      break;
    }
    case WM_NCMOUSELEAVE: {
      tracking_leave_ = false;
      SetHover(HTNOWHERE);
      LRESULT result = 0;
      DwmDefWindowProc(hwnd, message, wparam, lparam, &result);
      break;
    }
    case WM_NCLBUTTONDOWN:
    case WM_NCLBUTTONDBLCLK:
      if (wparam == HTMAXBUTTON) {
        pressed_button_ = HTMAXBUTTON;
        SetCapture(hwnd);
        PublishState();
        return 0;
      }
      break;  // HTCAPTION movement/double-click is handled by Windows itself.
    case WM_MOUSEMOVE:
      if (pressed_button_ != HTNOWHERE) {
        SetHover(HitTest(CursorPosition()));
        return 0;
      }
      SetHover(HTNOWHERE);
      break;
    case WM_LBUTTONUP:
      if (pressed_button_ != HTNOWHERE) {
        const bool activate = HitTest(CursorPosition()) == pressed_button_;
        CancelButtonPress();
        if (activate) {
          PostMessage(hwnd, WM_SYSCOMMAND,
                       IsZoomed(hwnd) ? SC_RESTORE : SC_MAXIMIZE, 0);
        }
        return 0;
      }
      break;
    case WM_CAPTURECHANGED:
    case WM_CANCELMODE:
      CancelButtonPress();
      break;
    case WM_NCRBUTTONUP:
      if (wparam == HTCAPTION) {
        const HMENU menu = GetSystemMenu(hwnd, FALSE);
        const bool maximized = IsZoomed(hwnd) != FALSE;
        EnableMenuItem(menu, SC_RESTORE, MF_BYCOMMAND | (maximized ? MF_ENABLED : MF_GRAYED));
        EnableMenuItem(menu, SC_MAXIMIZE, MF_BYCOMMAND | (maximized ? MF_GRAYED : MF_ENABLED));
        EnableMenuItem(menu, SC_MOVE, MF_BYCOMMAND | (maximized ? MF_GRAYED : MF_ENABLED));
        EnableMenuItem(menu, SC_SIZE, MF_BYCOMMAND | (maximized ? MF_GRAYED : MF_ENABLED));
        const UINT command = TrackPopupMenu(
            menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, GET_X_LPARAM(lparam),
            GET_Y_LPARAM(lparam), 0, hwnd, nullptr);
        if (command) PostMessage(hwnd, WM_SYSCOMMAND, command, 0);
        return 0;
      }
      break;
    case WM_SIZE:
    case WM_ACTIVATE:
      PublishState();
      break;
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK DesktopWindow::WindowProc(HWND hwnd, UINT message,
                                            WPARAM wparam, LPARAM lparam,
                                            UINT_PTR id, DWORD_PTR data) {
  if (message == WM_NCDESTROY) {
    RemoveWindowSubclass(hwnd, WindowProc, id);
    return DefSubclassProc(hwnd, message, wparam, lparam);
  }
  return reinterpret_cast<DesktopWindow*>(data)->HandleMessage(
      hwnd, message, wparam, lparam);
}

LRESULT CALLBACK DesktopWindow::ContentProc(HWND hwnd, UINT message,
                                             WPARAM wparam, LPARAM lparam,
                                             UINT_PTR id, DWORD_PTR data) {
  if (message == WM_NCDESTROY) {
    RemoveWindowSubclass(hwnd, ContentProc, id);
  } else if (message == WM_NCHITTEST) {
    auto* self = reinterpret_cast<DesktopWindow*>(data);
    if (self->HitTest({GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)}) != HTCLIENT) {
      return HTTRANSPARENT;
    }
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}
