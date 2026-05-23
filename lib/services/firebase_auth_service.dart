import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

// Service untuk semua operasi autentikasi menggunakan Firebase Auth.
// Juga bertanggung jawab menyimpan data user ke Firestore saat registrasi.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan user yang sedang login (null jika belum login).
  User? currentUser() => _auth.currentUser;

  // Stream untuk memantau perubahan status autentikasi (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrasi user baru. Setelah berhasil, data juga disimpan ke collection "users".
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1) Buat akun di Firebase Authentication.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2) Update display name di Firebase Auth.
      await credential.user!.updateDisplayName(name);

      // 3) Buat objek UserModel & simpan ke Firestore.
      final user = UserModel(uid: uid, name: name, email: email.trim());
      await _firestore.collection('users').doc(uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      // Lempar pesan error yang lebih ramah untuk ditampilkan ke user.
      throw _mapAuthError(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Login dengan email & password.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Ambil data tambahan user dari Firestore.
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // Jika dokumen tidak ada (kasus jarang), buat dari Firebase Auth.
        return UserModel(
          uid: uid,
          name: credential.user!.displayName ?? '',
          email: credential.user!.email ?? '',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Logout user yang sedang login.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Memetakan kode error Firebase Auth ke pesan berbahasa Indonesia.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi';
    }
  }
}
