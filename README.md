# Mood Diary

Aplikasi Flutter untuk mencatat diary harian sekaligus memprediksi mood penggunanya secara otomatis menggunakan model gemini API. Dibuat sebagai Final Project mata kuliah **Pemrograman Perangkat Bergerak (PPB)**.

## Struktur Project

```
lib/
├── main.dart                   
├── firebase_options.dart      
├── models/
│   ├── diary_entry.dart        # Model entri diary (Firestore)
│   ├── mood_result.dart        # Model hasil prediksi mood
│   └── user_model.dart         # Model user
├── screens/
│   ├── login_screen.dart       # Halaman login
│   ├── register_screen.dart    # Halaman registrasi
│   ├── home_screen.dart        # Form tulis diary + analisis
│   ├── result_screen.dart      # Hasil prediksi mood
│   ├── history_screen.dart     # Riwayat diary
│   └── edit_diary_screen.dart  # Edit entri diary
└── services/
    ├── auth_service.dart            # ChangeNotifier untuk auth
    ├── firebase_auth_service.dart   # Wrapper Firebase Auth
    ├── diary_service.dart           # ChangeNotifier untuk diary
    ├── firestore_service.dart       # CRUD Firestore
    └── mood_api_service.dart        # Klien HuggingFace + fallback
```

## Persiapan & Setup

### 1. Prasyarat

- Flutter SDK `>=3.10.0`
- Akun Firebase + project Firebase yang sudah dibuat
- HuggingFace account untuk mendapatkan API token (opsional — ada fallback)

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
>>>>>>> 5103f2314a7ce4a9ce2bbf52518d5c9d23934dba
