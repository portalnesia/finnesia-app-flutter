#ifndef RUNNER_WINDOWS_EXIT_NOTICE_H_
#define RUNNER_WINDOWS_EXIT_NOTICE_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

// Answers `pos/exit_notice` (`exit_notice_channel.dart`) on Windows.
//
// Shutting Windows down or signing out never reaches the Dart side, so the open-shift reminder
// is handed to Windows beforehand: while one is set it is registered as the window's
// shutdown-block reason, and the window answers WM_QUERYENDSESSION with "not yet". Windows then
// shows its own "an app is preventing shutdown" screen with this reason, and "shut down anyway"
// is still the cashier's to choose. A reminder, not a lock.
//
// The window close (title-bar X, Alt+F4) is held here too while a reminder is set. Flutter's
// engine asks the framework about a close only when its window is the process's last top-level
// window (`WindowsLifecycleManager::IsLastWindowOfProcess`), and pdfium, loaded by the `printing`
// plugin, starts GDI+, whose hidden "GDI+ Window" is a second one: the close then went straight
// through and the reminder never showed. So the runner answers the close itself and asks the app
// with `closeRequested`; the app shows the reminder and leaves with `exitApplication(required)`,
// which quits without another WM_CLOSE.
class WindowsExitNotice {
 public:
  using Value = flutter::EncodableValue;
  using Channel = flutter::MethodChannel<Value>;

  WindowsExitNotice(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsExitNotice();

  // Whether WM_QUERYENDSESSION should be answered FALSE: true while a reminder is set.
  bool HoldsEndSession() const { return has_notice_; }

  // Whether WM_CLOSE should be held for the app to decide: true while a reminder is set.
  bool HoldsClose() const { return has_notice_; }

  // Asks the app (`closeRequested` on the channel) what to do about a close that was held.
  void RequestClose();

 private:
  void HandleMethodCall(const flutter::MethodCall<Value>& call,
                        std::unique_ptr<flutter::MethodResult<Value>> result);
  void Clear();

  std::unique_ptr<Channel> channel_;
  HWND window_;
  bool has_notice_ = false;
};

#endif  // RUNNER_WINDOWS_EXIT_NOTICE_H_
