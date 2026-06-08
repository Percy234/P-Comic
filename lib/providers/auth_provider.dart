import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;
  bool isLoading = false;
  String? errorMessage;

  String _translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'user-disabled':
        return 'Tài khoản này đã bị tạm khóa.';
      case 'user-not-found':
        return 'Tài khoản email này chưa được đăng ký.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký bởi tài khoản khác.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
      case 'operation-not-allowed':
        return 'Tính năng đăng nhập này hiện chưa được kích hoạt.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra mạng internet.';
      case 'too-many-requests':
        return 'Quá nhiều lượt thử đăng nhập thất bại. Tài khoản bị tạm khóa, vui lòng thử lại sau.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'channel-error':
        return 'Vui lòng điền đầy đủ thông tin.';
      default:
        return e.message ?? 'Đã xảy ra lỗi không xác định.';
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _translateError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _translateError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}