#include <app_links/app_links_plugin_c_api.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cwchar>

#include "flutter_window.h"
#include "utils.h"
#include "windows_wns_push_messaging.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // WNS uses a COM-server argument and must reach AppInstance redirection below. The app_links
  // helper handles normal secondary launches; keep browser-link behavior unchanged.
  const bool is_windows_app_sdk_push_activation =
      std::wcsstr(command_line, L"WindowsAppRuntimePushServer:") != nullptr;
  if (!is_windows_app_sdk_push_activation && SendAppLinkToInstance()) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  if (WindowsWnsPushMessaging::InitializeAndRedirectActivation()) {
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // The title bar and the taskbar entry. The product name, not the binary name: this is the
  // one a person reads. Same string as the Android launcher label (`@string/app_name`).
  if (!window.Create(L"Finnesia POS", origin, size)) {
    WindowsWnsPushMessaging::Unregister();
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  WindowsWnsPushMessaging::Unregister();
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
