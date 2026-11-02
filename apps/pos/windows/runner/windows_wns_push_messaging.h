#ifndef RUNNER_WINDOWS_WNS_PUSH_MESSAGING_H_
#define RUNNER_WINDOWS_WNS_PUSH_MESSAGING_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <string>

// Bridges the Windows App SDK WNS APIs to the POS PushMessagingPort.
class WindowsWnsPushMessaging {
 public:
  using Value = flutter::EncodableValue;
  using Channel = flutter::MethodChannel<Value>;

  explicit WindowsWnsPushMessaging(flutter::BinaryMessenger* messenger);
  ~WindowsWnsPushMessaging();

  // Called before Flutter starts, so WNS handlers exist before activation is read.
  // Returns true when the process was redirected to an already-running instance.
  static bool InitializeAndRedirectActivation();

  static void Unregister();
  static bool IsAvailable();
  static void SetWindowHandle(HWND window);
  static bool HandleWindowMessage(UINT message);
  static void RouteNativeEvent(const std::string& method,
                               const std::string& payload);

 private:
  void HandleMethodCall(
      const flutter::MethodCall<Value>& call,
      std::unique_ptr<flutter::MethodResult<Value>> result);
  void EmitNativeEvent(const std::string& method, const std::string& payload);

  std::unique_ptr<Channel> channel_;
  bool channel_ready_ = false;
};

#endif  // RUNNER_WINDOWS_WNS_PUSH_MESSAGING_H_
