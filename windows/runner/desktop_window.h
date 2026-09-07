#ifndef RUNNER_DESKTOP_WINDOW_H_
#define RUNNER_DESKTOP_WINDOW_H_

#include <windows.h>
#include <commctrl.h>
#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

#include <memory>
#include <vector>

// Native hit testing stays outside Flutter's gesture arena. In particular,
// the Flutter child HWND must pass caption/resize hits to its parent HWND.
class DesktopWindow {
 public:
  DesktopWindow(HWND window, HWND content,
                flutter::BinaryMessenger* messenger);
  ~DesktopWindow();
  DesktopWindow(const DesktopWindow&) = delete;
  DesktopWindow& operator=(const DesktopWindow&) = delete;

 private:
  struct Region {
    double left;
    double top;
    double right;
    double bottom;
    int hit;
  };

  static LRESULT CALLBACK WindowProc(HWND, UINT, WPARAM, LPARAM,
                                     UINT_PTR, DWORD_PTR);
  static LRESULT CALLBACK ContentProc(HWND, UINT, WPARAM, LPARAM,
                                      UINT_PTR, DWORD_PTR);
  LRESULT HandleMessage(HWND, UINT, WPARAM, LPARAM);
  int HitTest(POINT screen_point) const;
  void UpdateRegions(const flutter::EncodableValue* arguments);
  flutter::EncodableValue State() const;
  void PublishState();
  void SetHover(int hit);
  void CancelButtonPress();
  void SetMaximizedClientRect(RECT* rect) const;

  HWND window_;
  HWND content_;
  std::vector<Region> regions_;
  int hovered_button_ = HTNOWHERE;
  int pressed_button_ = HTNOWHERE;
  int64_t revision_ = 0;
  bool tracking_leave_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif
