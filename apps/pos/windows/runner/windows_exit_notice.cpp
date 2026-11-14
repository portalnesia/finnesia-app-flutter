#include "windows_exit_notice.h"

#include <string>

namespace {

constexpr char kChannelName[] = "pos/exit_notice";

// Windows wants the reason as UTF-16; the channel carries UTF-8.
std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  const int length = ::MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(), static_cast<int>(utf8.size()),
      nullptr, 0);
  if (length <= 0) return std::wstring();
  std::wstring utf16(length, L'\0');
  ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                        static_cast<int>(utf8.size()), utf16.data(), length);
  return utf16;
}

const std::string* StringArgument(const flutter::EncodableMap& arguments,
                                  const char* key) {
  const auto found = arguments.find(flutter::EncodableValue(key));
  if (found == arguments.end()) return nullptr;
  return std::get_if<std::string>(&found->second);
}

}  // namespace

WindowsExitNotice::WindowsExitNotice(flutter::BinaryMessenger* messenger,
                                     HWND window)
    : window_(window) {
  channel_ = std::make_unique<Channel>(
      messenger, kChannelName, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<Value>& call,
             std::unique_ptr<flutter::MethodResult<Value>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

WindowsExitNotice::~WindowsExitNotice() {
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  Clear();
}

void WindowsExitNotice::HandleMethodCall(
    const flutter::MethodCall<Value>& call,
    std::unique_ptr<flutter::MethodResult<Value>> result) {
  if (call.method_name() == "clear") {
    Clear();
    result->Success();
    return;
  }
  if (call.method_name() != "set") {
    result->NotImplemented();
    return;
  }

  const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
  const std::string* body =
      arguments == nullptr ? nullptr : StringArgument(*arguments, "body");
  if (body == nullptr) {
    result->Error("bad_args", "body is required");
    return;
  }
  // The body names the shift and what to do about it; Windows shows it under the app's name,
  // so the title would only repeat what the app's name already frames.
  const std::wstring reason = Utf16FromUtf8(*body);
  if (reason.empty() || !::ShutdownBlockReasonCreate(window_, reason.c_str())) {
    result->Error("not_set", "Windows refused the shutdown reason");
    return;
  }
  has_notice_ = true;
  result->Success();
}

void WindowsExitNotice::Clear() {
  if (!has_notice_) return;
  ::ShutdownBlockReasonDestroy(window_);
  has_notice_ = false;
}
