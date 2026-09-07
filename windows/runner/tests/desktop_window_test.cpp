#include "desktop_window.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <windowsx.h>

#include <cstdlib>
#include <iostream>
#include <string>
#include <utility>

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using List = flutter::EncodableList;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAILED: " << message << std::endl;
    std::exit(1);
  }
}

class Messenger : public flutter::BinaryMessenger {
 public:
  mutable std::vector<Map> states;
  flutter::BinaryMessageHandler handler;

  void Send(const std::string&, const uint8_t* data, size_t size,
            flutter::BinaryReply reply = nullptr) const override {
    const auto& codec = flutter::StandardMethodCodec::GetInstance();
    auto call = codec.DecodeMethodCall(data, size);
    if (call && call->method_name() == "stateChanged") {
      states.push_back(std::get<Map>(*call->arguments()));
    }
    if (reply) {
      auto response = codec.EncodeSuccessEnvelope();
      reply(response->data(), response->size());
    }
  }

  void SetMessageHandler(const std::string&,
                         flutter::BinaryMessageHandler callback) override {
    handler = std::move(callback);
  }

  Value Invoke(const std::string& method, Value value = Value()) {
    Check(handler != nullptr, "bridge handler must be installed");
    const auto& codec = flutter::StandardMethodCodec::GetInstance();
    auto request = codec.EncodeMethodCall(flutter::MethodCall<Value>(
        method, std::make_unique<Value>(value)));
    Value response;
    bool completed = false;
    flutter::MethodResultFunctions<Value> result(
        [&](const Value* reply) {
          if (reply) response = *reply;
          completed = true;
        },
        [&](const std::string&, const std::string&, const Value*) {
          Check(false, "native method returned an error");
        },
        [&]() { Check(false, "native method was not implemented"); });
    handler(request->data(), request->size(), [&](const uint8_t* data, size_t size) {
      Check(codec.DecodeAndProcessResponseEnvelope(data, size, &result),
             "valid method response");
    });
    Check(completed, "native method must reply");
    return response;
  }
};

POINT ScreenPoint(HWND child, double x, double y, double scale) {
  POINT point{static_cast<LONG>(x * scale), static_cast<LONG>(y * scale)};
  ClientToScreen(child, &point);
  return point;
}

LRESULT Hit(HWND window, POINT point) {
  return SendMessage(window, WM_NCHITTEST, 0, MAKELPARAM(point.x, point.y));
}
}  // namespace

int main() {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  WNDCLASSW klass{};
  klass.lpfnWndProc = DefWindowProcW;
  klass.hInstance = GetModuleHandle(nullptr);
  klass.lpszClassName = L"DesktopWindowNativeTest";
  Check(RegisterClassW(&klass) != 0, "register hidden test window");
  HWND window = CreateWindowW(klass.lpszClassName, L"Window test", WS_OVERLAPPEDWINDOW,
                              100, 100, 1200, 800, nullptr, nullptr, klass.hInstance, nullptr);
  Check(window != nullptr, "create hidden window");
  HWND child = CreateWindowW(klass.lpszClassName, L"", WS_CHILD | WS_VISIBLE,
                             0, 0, 100, 100, window, nullptr, klass.hInstance, nullptr);
  Check(child != nullptr, "create Flutter-like child HWND");
  Messenger messenger;
  {
    DesktopWindow bridge(window, child, &messenger);
    RECT client{};
    GetClientRect(window, &client);
    MoveWindow(child, 0, 0, client.right, client.bottom, FALSE);
    const double scale = GetDpiForWindow(window) / 96.0;
    const double width = client.right / scale;
    messenger.Invoke("setRegions", Value(List{
        Value(List{Value(12.0), Value(0.0), Value(160.0), Value(44.0), Value("caption")}),
        Value(List{Value(224.0), Value(0.0), Value(width - 138), Value(44.0), Value("caption")}),
        Value(List{Value(width - 92), Value(0.0), Value(width - 46), Value(44.0), Value("maximize")}),
    }));

    const POINT caption = ScreenPoint(child, 80, 24, scale);
    Check(Hit(window, caption) == HTCAPTION, "native draggable caption");
    Check(Hit(child, caption) == HTTRANSPARENT, "child must forward caption hit to parent");
    const POINT button = ScreenPoint(child, width - 69, 24, scale);
    Check(Hit(window, button) == HTMAXBUTTON, "maximize advertises Windows Snap Layouts");
    Check(Hit(child, button) == HTTRANSPARENT, "child must forward maximize hit to parent");
    const POINT action = ScreenPoint(child, 190, 24, scale);
    Check(Hit(window, action) == HTCLIENT, "sidebar keeps client input");
    Check(Hit(child, action) == HTCLIENT, "child keeps interactive action input");

    RECT outer{};
    GetWindowRect(window, &outer);
    Check(Hit(window, {outer.left + 1, outer.top + 1}) == HTTOPLEFT,
           "top-left native resize hit");
    Check(Hit(child, {outer.left + 1, outer.top + 1}) == HTTRANSPARENT,
           "child must not swallow resize edges");
    MINMAXINFO limits{};
    SendMessage(window, WM_GETMINMAXINFO, 0, reinterpret_cast<LPARAM>(&limits));
    Check(limits.ptMinTrackSize.x == static_cast<LONG>(480 * scale),
           "minimum width permits narrow snapped layouts");
    Check(limits.ptMinTrackSize.y == static_cast<LONG>(360 * scale),
           "minimum height follows DPI");

    // Exercise maximized state without showing a window or moving the user's
    // pointer/focus. WM_SIZE is the notification used by actual system changes.
    const LONG_PTR style = GetWindowLongPtr(window, GWL_STYLE);
    SetWindowLongPtr(window, GWL_STYLE, style | WS_MAXIMIZE);
    SendMessage(window, WM_SIZE, SIZE_MAXIMIZED, 0);
    Check(!messenger.states.empty(), "system size changes publish state");
    Check(std::get<bool>(messenger.states.back().at(Value("maximized"))),
           "published state uses the native maximized state");
    Check(Hit(window, button) == HTMAXBUTTON, "restore button retains Snap hit when maximized");
    Check(Hit(window, {outer.left + 1, outer.top + 1}) == HTCLIENT,
           "maximized windows do not expose resize borders");
    SetWindowLongPtr(window, GWL_STYLE, style);
    SendMessage(window, WM_SIZE, SIZE_RESTORED, 0);
    const auto restored = std::get<Map>(messenger.Invoke("getState"));
    Check(!std::get<bool>(restored.at(Value("maximized"))), "getState reports system restore");

    messenger.Invoke("setRegions", Value(List{}));
    Check(Hit(window, caption) == HTCLIENT, "clearing regions removes stale drag targets");
  }
  Check(messenger.handler == nullptr, "bridge unregisters method handler on shutdown");
  DestroyWindow(window);
  UnregisterClassW(klass.lpszClassName, klass.hInstance);
  std::cout << "Native HWND hit testing, resize, DPI, state and teardown checks passed." << std::endl;
  return 0;
}
