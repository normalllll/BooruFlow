// Compiled only into the separate UI automation runner.
#ifndef RUNNER_AUTOMATION_WINDOW_H_
#define RUNNER_AUTOMATION_WINDOW_H_
#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <functional>
struct AutomationPlacement { int x; int y; int width; int height; };
AutomationPlacement GetAutomationPlacement();
class AutomationWindow {
 public:
  AutomationWindow(flutter::BinaryMessenger* messenger, HWND window,
                   std::function<void()> redraw);
  void Activated() { ++activation_count_; }
 private:
  HWND window_;
  int activation_count_ = 0;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};
#endif
