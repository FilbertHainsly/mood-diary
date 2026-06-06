# Mood Diary

Aplikasi Flutter untuk mencatat diary harian sekaligus memprediksi mood penggunanya secara otomatis menggunakan model gemini API. Dibuat sebagai Final Project mata kuliah **Pemrograman Perangkat Bergerak (PPB)**.

## Struktur Project


```
lib/
│   firebase_options.dart
│   main.dart
│   
├───core
│       app_theme.dart
│       
├───models
│       chat_message.dart
│       chat_session.dart
│       diary_entry.dart
│       mood_result.dart
│       user_model.dart
│       
├───screens
│   ├───analytics
│   │       analytics_screen.dart
│   │       
│   ├───auth
│   │       login_screen.dart
│   │       register_screen.dart
│   │       
│   ├───chat
│   │       chat_list_screen.dart
│   │       chat_room_screen.dart
│   │       
│   ├───diary
│   │       diary_list_screen.dart
│   │       edit_diary_screen.dart
│   │       result_screen.dart
│   │       write_diary_screen.dart
│   │       
│   └───home
│           home_screen.dart
│           main_navigation_screen.dart
│           
├───services
│       analytics_service.dart
│       auth_service.dart
│       chat_service.dart
│       diary_service.dart
│       firebase_auth_service.dart
│       firestore_service.dart
│       local_storage_service.dart
│       mood_api_service.dart
│       
└───widgets
        diary_card.dart
        loading_widget.dart
        mood_badge.dart
```


## Persiapan & Setup

### 1. Prasyarat

- Flutter SDK `>=3.10.0`
- Akun Firebase + project Firebase yang sudah dibuat

### 2. Clone & Install Dependencies

```bash
git clone <repo-url>
cd mood_diary
flutter pub get
```

### 3. Konfigurasi Firebase

Project sudah berisi `lib/firebase_options.dart` yang di-generate oleh FlutterFire CLI. Jika ingin pakai project Firebase Anda sendiri:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pastikan di Firebase Console:
- **Authentication** → enable provider **Email/Password**.
- **Cloud Firestore** → buat database (production / test mode).

### 4. Gemini API Token

Buka [lib/services/mood_api_service.dart](lib/services/mood_api_service.dart#L18) dan ganti nilai `_geminiApiKey` dengan token milik Anda. Token bisa dibuat di Google AI Studio.

> Jika token tidak diset / request gagal, app otomatis pakai fallback keyword predictor.

### 5. Jalankan App

```bash
flutter run
```
=======
##  Class Diagram

![Class Diagram](https://github.com/user-attachments/assets/edf24662-4429-4e53-998e-eddc7883626a)
>  ([Link Diagram](https://drive.google.com/file/d/1qaYikw3Q80jyeQ_0Wjic_2kIu9O03UhY/view))  

### Penjelasan Singkat
Class diagram ini menggambarkan struktur aplikasi Mood Diary yang terbagi menjadi:
- **Model Classes**: User, DiaryEntry, ChatSession, Message, TrustedContact
- **Service Classes**: AuthService, FirestoreService, EmotionApiService, GeminiApiService, NotificationService
