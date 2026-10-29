cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "windows_wns_push_messaging.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# WNS is enabled only for a configured, packaged Windows App SDK build. The app ID and service
# principal object ID are public identifiers supplied by the owner at build time, never secrets.
set(FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR "$ENV{FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR}" CACHE PATH
    "Directory containing Windows App SDK C++/WinRT include/winrt headers")
set(FINNESIA_POS_WNS_APP_ID "$ENV{FINNESIA_POS_WNS_APP_ID}")
set(FINNESIA_POS_WNS_OBJECT_ID "$ENV{FINNESIA_POS_WNS_OBJECT_ID}")
if(FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR AND
   EXISTS "${FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR}/winrt/Microsoft.Windows.PushNotifications.h" AND
   EXISTS "${FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR}/winrt/Microsoft.Windows.AppLifecycle.h" AND
   FINNESIA_POS_WNS_APP_ID AND FINNESIA_POS_WNS_OBJECT_ID)
  target_include_directories(${BINARY_NAME} PRIVATE "${FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR}")
  target_compile_definitions(${BINARY_NAME} PRIVATE
    FINNESIA_POS_WINDOWS_APP_SDK_AVAILABLE
    "FINNESIA_POS_WNS_APP_ID=\"${FINNESIA_POS_WNS_APP_ID}\""
    "FINNESIA_POS_WNS_OBJECT_ID=\"${FINNESIA_POS_WNS_OBJECT_ID}\"")
  target_link_libraries(${BINARY_NAME} PRIVATE "windowsapp.lib")
  message(STATUS "Finnesia POS WNS bridge enabled for the configured packaged app")
else()
  message(STATUS "Finnesia POS WNS bridge disabled; app remains buildable without WNS identifiers/SDK")
endif()

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
