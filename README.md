# Mood Diary

Aplikasi Flutter untuk mencatat diary harian sekaligus memprediksi mood penggunanya secara otomatis menggunakan model AI klasifikasi emosi Bahasa Indonesia. Dibuat sebagai Final Project mata kuliah **Pemrograman Perangkat Bergerak (PPB)**.

## Fitur Utama

- **Autentikasi** — Register & login menggunakan Firebase Authentication (email + password).
- **Tulis Diary** — Tulis catatan harian lewat form sederhana dengan validasi minimal karakter.
- **Prediksi Mood Otomatis** — Teks diary dikirim ke model `StevenLimcorn/indonesian-roberta-base-emotion-classifier` di HuggingFace Inference API. Mendukung 6 mood: **Happy, Sad, Angry, Fear, Love, Neutral**.
- **Fallback Predictor** — Jika API gagal / token belum diset, aplikasi otomatis fallback ke keyword-based predictor lokal sehingga tetap bisa didemonstrasikan.
- **Riwayat Diary** — Semua entri tersimpan di Cloud Firestore per user dan dapat ditampilkan, di-edit, maupun dihapus.
- **Tema Konsisten** — Palet tosca & soft orange dengan mapping warna + emoji untuk setiap mood.

## Tech Stack

| Kategori | Teknologi |
| --- | --- |
| Framework | Flutter (Dart SDK `>=3.0.0 <4.0.0`) |
| State Management | `provider` ^6.1.2 |
| Auth | `firebase_auth` ^4.17.8 |
| Database | `cloud_firestore` ^4.15.8 |
| HTTP Client | `http` ^1.2.1 |
| AI / NLP | HuggingFace Inference API — RoBERTa fine-tuned Bahasa Indonesia |
| Formatter | `intl` ^0.19.0 |

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

### 4. HuggingFace API Token

Buka [lib/services/mood_api_service.dart](lib/services/mood_api_service.dart#L18) dan ganti nilai `_hfToken` dengan token milik Anda. Token bisa dibuat di https://huggingface.co/settings/tokens (cukup role **Read**).

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
