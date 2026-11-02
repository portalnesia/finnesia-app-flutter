#include "windows_wns_push_messaging.h"

#include <appmodel.h>

#include <atomic>
#include <deque>
#include <mutex>
#include <string>
#include <utility>

#if defined(FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE)
#include <winrt/Microsoft.Windows.AppLifecycle.h>
#include <winrt/Microsoft.Windows.PushNotifications.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.h>
#endif

namespace {
std::mutex g_state_mutex;
WindowsWnsPushMessaging* g_instance = nullptr;
HWND g_window_handle = nullptr;
std::atomic_bool g_available = false;
std::string g_initial_activation;
std::deque<std::pair<std::string, std::string>> g_pending_native_events;
constexpr UINT kWnsNativeEventMessage = WM_APP + 0x135;

#if defined(FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE)
using namespace winrt::Microsoft::Windows::AppLifecycle;
using namespace winrt::Microsoft::Windows::PushNotifications;
using namespace winrt::Windows::Data::Xml::Dom;
using namespace winrt::Windows::Foundation;

std::string ExtractToastLaunch(const std::string& payload) {
  const auto first = payload.find_first_not_of(" \t\r\n");
  if (first == std::string::npos) return {};
  if (payload[first] == '{') return payload;

  try {
    XmlDocument document;
    document.LoadXml(winrt::to_hstring(payload));
    const auto node = document.SelectSingleNode(L"/toast");
    if (!node) return {};
    const auto toast = node.as<XmlElement>();
    return winrt::to_string(toast.GetAttribute(L"launch"));
  } catch (const winrt::hresult_error&) {
    return {};
  } catch (...) {
    return {};
  }
}

std::string ExtractToastLaunch(const PushNotificationReceivedEventArgs& args) {
  const auto payload = args.Payload();
  return ExtractToastLaunch(
      std::string(payload.begin(), payload.end()));
}

bool HasPackageIdentity() {
  UINT32 package_family_name_length = 0;
  const auto status =
      GetCurrentPackageFamilyName(&package_family_name_length, nullptr);
  return status != APPMODEL_ERROR_NO_PACKAGE && package_family_name_length > 0;
}

bool HasValidWnsIds() {
  try {
    const winrt::guid app_id{FINNESIA_POS_WNS_APP_ID};
    const winrt::guid object_id{FINNESIA_POS_WNS_OBJECT_ID};
    return app_id != winrt::guid{} && object_id != winrt::guid{};
  } catch (const winrt::hresult_error&) {
    return false;
  }
}

void HandleActivation(const AppActivationArguments& arguments) {
  if (arguments.Kind() != ExtendedActivationKind::Push) return;
  const auto push = arguments.Data().try_as<PushNotificationReceivedEventArgs>();
  if (!push) return;

  const auto deferral = push.GetDeferral();
  try {
    const auto launch = ExtractToastLaunch(push);
    if (!launch.empty()) {
      WindowsWnsPushMessaging::RouteNativeEvent("notificationOpened", launch);
    }
  } catch (...) {
    // Activation remains best-effort; complete the OS deferral even on parse failure.
  }
  deferral.Complete();
}
#endif  // FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE
}  // namespace

WindowsWnsPushMessaging::WindowsWnsPushMessaging(
    flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<Channel>(
      messenger, "pos/windows_wns",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<Value>& call,
             std::unique_ptr<flutter::MethodResult<Value>> result) {
        HandleMethodCall(call, std::move(result));
      });

  std::lock_guard<std::mutex> lock(g_state_mutex);
  g_instance = this;
}

WindowsWnsPushMessaging::~WindowsWnsPushMessaging() {
  std::lock_guard<std::mutex> lock(g_state_mutex);
  if (g_instance == this) g_instance = nullptr;
  if (channel_) channel_->SetMethodCallHandler(nullptr);
}

bool WindowsWnsPushMessaging::InitializeAndRedirectActivation() {
#if defined(FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE)
  if (g_available.load()) return false;
  if (!HasPackageIdentity() || !HasValidWnsIds()) return false;

  bool manager_registered = false;
  try {
    if (!PushNotificationManager::IsSupported()) return false;

    auto& manager = PushNotificationManager::Default();
    manager.PushReceived(
        [](const PushNotificationManager&,
           const PushNotificationReceivedEventArgs& arguments) {
          const auto launch = ExtractToastLaunch(arguments);
          if (!launch.empty()) {
            RouteNativeEvent("pushReceived", launch);
          }
        });

    const auto current = AppInstance::GetCurrent();
    const auto registered = AppInstance::FindOrRegisterForKey(L"finnesia-pos");
    if (!registered.IsCurrent()) {
      // Register before reading activation data, as required by the WNS runtime.
      manager.Register();
      manager_registered = true;
      try {
        const auto activation = current.GetActivatedEventArgs();
        registered.RedirectActivationToAsync(activation).get();
      } catch (...) {
        manager.Unregister();
        manager_registered = false;
        throw;
      }
      manager.Unregister();
      manager_registered = false;
      return true;
    }

    registered.Activated(
        [](const AppInstance&, const AppActivationArguments& arguments) {
          HandleActivation(arguments);
        });

    manager.Register();
    manager_registered = true;
    g_available.store(true);
    // Register first: Windows App SDK requires this order before activation is queried.
    HandleActivation(current.GetActivatedEventArgs());
    return false;
  } catch (const winrt::hresult_error&) {
    if (manager_registered) {
      try {
        PushNotificationManager::Default().Unregister();
      } catch (...) {
      }
    }
    g_available.store(false);
    return false;
  } catch (...) {
    if (manager_registered) {
      try {
        PushNotificationManager::Default().Unregister();
      } catch (...) {
      }
    }
    g_available.store(false);
    return false;
  }
#else
  return false;
#endif  // FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE
}

bool WindowsWnsPushMessaging::IsAvailable() {
  return g_available.load();
}

void WindowsWnsPushMessaging::SetWindowHandle(HWND window) {
  bool has_pending_events = false;
  {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    g_window_handle = window;
    if (window == nullptr) {
      g_pending_native_events.clear();
    } else {
      has_pending_events = !g_pending_native_events.empty();
    }
  }
  if (has_pending_events) {
    PostMessage(window, kWnsNativeEventMessage, 0, 0);
  }
}

bool WindowsWnsPushMessaging::HandleWindowMessage(UINT message) {
  if (message != kWnsNativeEventMessage) return false;

  std::deque<std::pair<std::string, std::string>> pending_events;
  WindowsWnsPushMessaging* instance = nullptr;
  {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    pending_events.swap(g_pending_native_events);
    instance = g_instance;
  }
  if (instance != nullptr) {
    for (const auto& event : pending_events) {
      instance->EmitNativeEvent(event.first, event.second);
    }
  }
  return true;
}

void WindowsWnsPushMessaging::Unregister() {
#if defined(FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE)
  if (!g_available.exchange(false)) return;
  try {
    PushNotificationManager::Default().Unregister();
  } catch (...) {
    // Shutdown must not prevent the POS process from exiting.
  }
#endif  // FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE
}

void WindowsWnsPushMessaging::RouteNativeEvent(const std::string& method,
                                               const std::string& payload) {
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    if (g_instance == nullptr || !g_instance->channel_ready_) {
      if (method == "notificationOpened") g_initial_activation = payload;
      return;
    }
    g_pending_native_events.emplace_back(method, payload);
    window = g_window_handle;
  }
  if (window != nullptr) PostMessage(window, kWnsNativeEventMessage, 0, 0);
}

void WindowsWnsPushMessaging::EmitNativeEvent(const std::string& method,
                                              const std::string& payload) {
  if (!channel_) return;
  channel_->InvokeMethod(method, std::make_unique<Value>(payload));
}

void WindowsWnsPushMessaging::HandleMethodCall(
    const flutter::MethodCall<Value>& call,
    std::unique_ptr<flutter::MethodResult<Value>> result) {
  if (call.method_name() == "initialize") {
    {
      std::lock_guard<std::mutex> lock(g_state_mutex);
      channel_ready_ = true;
    }
    result->Success(Value(IsAvailable()));
    return;
  }

  if (call.method_name() == "initialActivation") {
    std::string activation;
    {
      std::lock_guard<std::mutex> lock(g_state_mutex);
      activation = std::move(g_initial_activation);
      g_initial_activation.clear();
    }
    if (activation.empty()) {
      result->Success(Value());
    } else {
      result->Success(Value(std::move(activation)));
    }
    return;
  }

  if (call.method_name() == "createChannel") {
#if defined(FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE)
    if (!IsAvailable()) {
      result->Success(Value());
      return;
    }
    try {
      const winrt::guid object_id{FINNESIA_POS_WNS_OBJECT_ID};
      auto operation =
          PushNotificationManager::Default().CreateChannelAsync(object_id);
      auto shared_result =
          std::shared_ptr<flutter::MethodResult<Value>>(std::move(result));
      operation.Completed(
          [shared_result](const auto& op, AsyncStatus status) {
            try {
              if (status != AsyncStatus::Completed) {
                shared_result->Success(Value());
                return;
              }
              const auto channel_result = op.GetResults();
              if (channel_result.Status() !=
                  PushNotificationChannelStatus::CompletedSuccess) {
                shared_result->Success(Value());
                return;
              }
              const auto channel = channel_result.Channel();
              shared_result->Success(Value(winrt::to_string(channel.Uri())));
            } catch (const winrt::hresult_error&) {
              shared_result->Success(Value());
            }
          });
    } catch (const winrt::hresult_error&) {
      result->Success(Value());
    }
#else
    result->Success(Value());
#endif  // FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE
    return;
  }

  result->NotImplemented();
}
