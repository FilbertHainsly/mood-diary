# Mood Diary

Aplikasi Flutter untuk mencatat diary harian sekaligus memprediksi mood pengguna secara otomatis menggunakan Gemini API. Dibuat sebagai Final Project mata kuliah **Pemrograman Perangkat Bergerak (PPB)**.

## Fitur

- **Diary** — tulis, edit, dan hapus catatan harian dengan tampilan seperti aplikasi Notes
- **Speech-to-Text Diary** — input diary lewat suara (Bahasa Indonesia / locale sistem) untuk write maupun edit
- **Analisis Mood Otomatis** — setiap diary dianalisis oleh Gemini AI untuk mendeteksi mood (positive, stable, anxious, stressed, depressed)
- **Statistik** — grafik tren harian/mingguan, distribusi mood, streak menulis, dan hari aktif
- **Rekomendasi Mood AI** — saran berbasis Gemini AI yang muncul pada kartu mood dominan untuk membantu pengguna merespons kondisi emosionalnya
- **Chat AI** — chatbot berbasis Gemini untuk bercerita dan mendapatkan respons empatik
- **Diary Reminder** — dialog pengingat untuk menulis diary yang muncul setelah login
- **Autentikasi** — login dan registrasi dengan Firebase Email/Password
- **Crash Monitoring** — Firebase Crashlytics untuk memantau crash dan error secara real-time, termasuk non-fatal error dari Gemini AI dan Speech-to-Text

## Struktur Project

```
lib/
├── config/
│   ├── secrets.dart          # API key (GITIGNORED — jangan commit)
│   └── secrets.example.dart  # Template API key
├── core/
│   └── app_theme.dart
├── models/
│   ├── chat_message.dart
│   ├── chat_session.dart
│   ├── diary_entry.dart
│   ├── mood_result.dart
│   └── user_model.dart
├── screens/
│   ├── analytics/
│   │   └── analytics_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── chat/
│   │   ├── chat_list_screen.dart
│   │   └── chat_room_screen.dart
│   ├── diary/
│   │   ├── diary_list_screen.dart
│   │   ├── edit_diary_screen.dart
│   │   ├── result_screen.dart
│   │   └── write_diary_screen.dart
│   └── home/
│       ├── home_screen.dart
│       └── main_navigation_screen.dart
├── services/
│   ├── analytics_service.dart
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── diary_service.dart
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   ├── mood_api_service.dart
│   ├── mood_recommendation_service.dart
│   └── speech_service.dart
├── firebase_options.dart
└── main.dart
```

## Persiapan & Setup

### 1. Prasyarat

- Flutter SDK `>=3.10.0`
- Akun Firebase + project Firebase yang sudah dibuat
- Gemini API key dari [Google AI Studio](https://aistudio.google.com)

### 2. Clone & Install Dependencies

```bash
git clone <repo-url>
cd mood_diary
flutter pub get
```

### 3. Konfigurasi Firebase

Project sudah berisi `lib/firebase_options.dart` yang di-generate oleh FlutterFire CLI. Jika ingin pakai project Firebase sendiri:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pastikan di Firebase Console:
- **Authentication** → aktifkan provider **Email/Password**
- **Cloud Firestore** → buat database (production / test mode)

### 4. Gemini API Key

Salin file template dan isi dengan API key milikmu:

```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
```

Buka `lib/config/secrets.dart` dan ganti nilai `geminiApiKey`:

```dart
class Secrets {
  static const String geminiApiKey = 'ISI_API_KEY_KAMU_DI_SINI';
}
```

> File `secrets.dart` sudah masuk `.gitignore` — tidak akan ter-commit ke repository.

> Di Windows PowerShell gunakan `Copy-Item lib/config/secrets.example.dart lib/config/secrets.dart` (atau `copy` di cmd) sebagai pengganti `cp`.

### 5. Permission Speech-to-Text

Permission untuk fitur rekam suara sudah dikonfigurasi:
- **Android** (`android/app/src/main/AndroidManifest.xml`) — `RECORD_AUDIO`, `INTERNET`, `POST_NOTIFICATIONS`
- **iOS** (`ios/Runner/Info.plist`) — `NSMicrophoneUsageDescription` dan `NSSpeechRecognitionUsageDescription`

Saat pertama kali menekan tombol mic, aplikasi akan meminta izin mikrofon ke user. Fitur ini membutuhkan koneksi internet karena memakai engine speech-to-text bawaan OS.

### 6. Aktifkan Firebase Crashlytics

Di [Firebase Console](https://console.firebase.google.com):
1. Pilih project → **Crashlytics** (sidebar Release & Monitor)
2. Klik **Enable Crashlytics**
3. Jalankan app sekali agar laporan pertama terkirim

Crashlytics akan otomatis menangkap crash, non-fatal error dari Gemini AI dan Speech-to-Text, serta mencatat aktivitas user sebelum crash terjadi.

### 7. Jalankan App

```bash
flutter run
```

## Class Diagram

![Class Diagram](https://github.com/user-attachments/assets/ac630778-4259-4dd2-91a5-034986870422)
> ([Link Diagram](https://drive.google.com/file/d/1qaYikw3Q80jyeQ_0Wjic_2kIu9O03UhY/view))
