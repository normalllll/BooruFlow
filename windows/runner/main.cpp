#include <algorithm>
#include <cmath>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  constexpr int kWindowWidth = 1200;
  constexpr int kWindowHeight = 900;
  const double scale_factor = GetDpiForSystem() / 96.0;
  RECT work_area{};
  if (!::SystemParametersInfoW(SPI_GETWORKAREA, 0, &work_area, 0)) {
    work_area.right = ::GetSystemMetrics(SM_CXSCREEN);
    work_area.bottom = ::GetSystemMetrics(SM_CYSCREEN);
  }

  const int work_area_x =
      static_cast<int>(std::round(work_area.left / scale_factor));
  const int work_area_y =
      static_cast<int>(std::round(work_area.top / scale_factor));
  const int work_area_width = static_cast<int>(
      std::round((work_area.right - work_area.left) / scale_factor));
  const int work_area_height = static_cast<int>(
      std::round((work_area.bottom - work_area.top) / scale_factor));
  const int window_width = std::min(kWindowWidth, work_area_width);
  const int window_height = std::min(kWindowHeight, work_area_height);
  const int window_x = work_area_x + (work_area_width - window_width) / 2;
  const int window_y = work_area_y + (work_area_height - window_height) / 2;

  Win32Window::Point origin(window_x, window_y);
  Win32Window::Size size(window_width, window_height);

  FlutterWindow window(project);
  if (!window.Create(L"BooruFlow", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
