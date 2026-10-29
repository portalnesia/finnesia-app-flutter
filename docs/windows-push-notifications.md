# WNS notifications untuk Finnesia POS Windows

POS Windows kini memiliki bridge WNS berbasis Windows App SDK. Saat konfigurasi tersedia, runner native mendaftarkan `PushReceived`, mengambil URI channel baru setiap aplikasi mulai, dan meneruskan activation toast ke Dart. Saat aplikasi sudah berjalan, launch kedua dari tap diarahkan ke instance POS yang ada. Payload activation hanya dipakai untuk mengambil `notification_id` dan `company_id`; isi notifikasi dan tautan tetap diambil dari server yang sudah memvalidasi tautan sebelum membukanya di browser sistem.

Android tetap menggunakan Firebase Cloud Messaging (FCM). Web dan platform lain tetap memakai adapter unsupported. Windows tidak memakai Firebase/FCM untuk jalur POS ini. Windows Settings tetap dapat mematikan notifikasi sistem; Windows tidak menampilkan permission prompt seperti Android.

## Yang wajib disiapkan pemilik

**WNS tidak aktif pada build Windows sampai semua prasyarat berikut tersedia.** Jika konfigurasi hilang, runner tetap dapat dibangun dan adapter dengan aman melaporkan WNS sebagai unsupported.

1. Buat/konfirmasi app registration Microsoft Entra yang **multi-tenant** untuk Windows App SDK push. Berikan tiga nilai kepada pemilik konfigurasi: Application (client) ID/AppId, Directory (tenant) ID, dan service-principal Object ID. AppId dan Object ID berupa GUID; jangan menebaknya. Tenant ID dan client secret dipakai backend saja—jangan menaruh client secret di aplikasi Flutter atau repo ini. `CreateChannelAsync` di Windows menggunakan Object ID.
2. Dapatkan **Package Family Name (PFN)** paket MSIX yang benar dari identitas Partner Center, lalu daftarkan pasangan PFN + AppId + Object ID dengan Microsoft melalui `Win_App_SDK_Push@microsoft.com`. Microsoft menyatakan pemetaan ini diperlukan untuk packaged Win32/MSIX. Jangan menyimpulkan PFN dari `identity_name` saja.
3. Gunakan header C++/WinRT Windows App SDK **1.7** saat membangun runner. Runtime Windows App SDK 1.7 juga harus tersedia pada perangkat target.
4. Konfigurasikan kredensial WNS pada backend melalui jalur konfigurasi server yang sudah didukung. Backend memang melewati delivery WNS saja jika kredensial itu belum ada; kredensial tersebut tidak termasuk dalam task Flutter ini.
5. Saat membuat MSIX, setel toast activator CLSID ke AppId yang sama dan argumen COM server ke `----WindowsAppRuntimePushServer:`. Manifest paket juga harus mempertahankan Store identity yang ditetapkan Partner Center.

Rujukan: [Push notifications quickstart](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/push-notifications/push-quickstart), [WNS overview](https://learn.microsoft.com/en-us/windows/apps/develop/notifications/push-notifications/wns-overview), dan [sample resmi Windows App SDK](https://github.com/microsoft/WindowsAppSDK-Samples/tree/main/Samples/Notifications/Push).

## Konfigurasi build Windows

Di mesin Windows, siapkan direktori header yang memiliki `winrt/Microsoft.Windows.PushNotifications.h` dan `winrt/Microsoft.Windows.AppLifecycle.h`. Sebelum mengonfigurasi ulang build, isi variabel environment berikut dengan nilai resmi pemilik:

```powershell
$env:FINNESIA_POS_WINDOWS_APP_SDK_INCLUDE_DIR = 'C:\path\to\windows-app-sdk\include'
$env:FINNESIA_POS_WNS_APP_ID = '<Entra Application (client) ID>'
$env:FINNESIA_POS_WNS_OBJECT_ID = '<service-principal Object ID>'
```

Lalu konfigurasi ulang dan bangun aplikasi Windows. Jika CMake sebelumnya pernah dikonfigurasi tanpa WNS, hapus `apps/pos/build/windows` terlebih dahulu agar nilai environment baru masuk ke cache. Packaging MSIX harus memakai pasangan nilai yang sama:

```powershell
flutter build windows --release
dart run msix:create --store `
  --toast-activator-clsid "$env:FINNESIA_POS_WNS_APP_ID" `
  --toast-activator-arguments '----WindowsAppRuntimePushServer:'
```

Perintah MSIX di atas menambahkan COM/toast activator dengan CLSID AppId. Runtime Windows App SDK 1.7 tetap harus dipasang atau dideploy ke target; generator MSIX dan workflow saat ini belum mendeklarasikan framework dependency itu. Untuk rilis CI, environment, dependency runtime, dan opsi MSIX yang sama perlu ditambahkan ke workflow Windows setelah pemilik menyediakan nilai tersebut; workflow yang ada belum mengatur WNS identifiers atau toast activator. Build `flutter run windows` tanpa package identity bukan jalur pengujian WNS/aktivasi MSIX.

## Perilaku dan privasi

Runner membuat channel baru pada startup; lifecycle controller juga meminta channel baru ketika aplikasi kembali aktif dan memperbarui registrasi POS memakai `platform=windows`, `app=pos`, locale, serta device fingerprint yang sama dengan pairing. Saat logout, URI terakhir yang benar-benar didaftarkan yang dikirim untuk unregister. URI channel hanya dikirim ke endpoint registrasi; token, rahasia, dan isi pesan tidak ditulis ke log.

Windows menampilkan toast WNS. Saat toast ditekan, aplikasi membuka item inbox dari server menggunakan ID; server tetap menjadi sumber data dan tautan, dan alur validasi/`open` browser sistem yang sudah ada tetap berlaku. URI WNS harus diteruskan sebagai nilai opaque; jangan mengubah host atau bagian URI-nya.
