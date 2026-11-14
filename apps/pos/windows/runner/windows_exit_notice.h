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
class WindowsExitNotice {
 public:
  using Value = flutter::EncodableValue;
  using Channel = flutter::MethodChannel<Value>;

  WindowsExitNotice(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsExitNotice();

  // Whether WM_QUERYENDSESSION should be answered FALSE: true while a reminder is set.
  bool HoldsEndSession() const { return has_notice_; }

 private:
  void HandleMethodCall(const flutter::MethodCall<Value>& call,
                        std::unique_ptr<flutter::MethodResult<Value>> result);
  void Clear();

  std::unique_ptr<Channel> channel_;
  HWND window_;
  bool has_notice_ = false;
};

#endif  // RUNNER_WINDOWS_EXIT_NOTICE_H_
