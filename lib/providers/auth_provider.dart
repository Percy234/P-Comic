import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

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
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty) {
        errorMessage = 'Tên đăng nhập không được để trống.';
        return false;
      }
      
      final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
      if (!usernameRegExp.hasMatch(normalizedUsername)) {
        errorMessage = 'Tên đăng nhập chỉ được chứa chữ cái, số, dấu gạch dưới (_) và có độ dài từ 3-20 ký tự.';
        return false;
      }

      final isTaken = await FirestoreService().isUsernameTaken(normalizedUsername);
      if (isTaken) {
        errorMessage = 'Tên đăng nhập này đã được sử dụng.';
        return false;
      }

      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(normalizedUsername);
        await FirestoreService().saveUsername(
          username: normalizedUsername,
          email: email.trim(),
          uid: user.uid,
        );

        // Gửi email xác thực trong try-catch riêng để không làm gián đoạn luồng đăng ký
        try {
          await user.sendEmailVerification();
        } catch (emailError) {
          debugPrint('LỖI GỬI EMAIL XÁC THỰC KHI ĐĂNG KÝ: $emailError');
          errorMessage = 'Đăng ký thành công nhưng không thể gửi email xác thực: $emailError';
          return true;
        }
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _translateError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    await user?.reload();
    notifyListeners();
  }

  Future<bool> sendVerificationEmail() async {
    try {
      await user?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('LỖI FIREBASE AUTH GỬI LẠI EMAIL: ${e.code} - ${e.message}');
      errorMessage = 'Lỗi xác thực email: ${_translateError(e)} (Mã: ${e.code})';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('LỖI KHÁC KHI GỬI LẠI EMAIL: $e');
      errorMessage = 'Lỗi gửi email: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      String email = emailOrUsername.trim();
      if (!email.contains('@')) {
        final resolvedEmail = await FirestoreService().getEmailByUsername(email);
        if (resolvedEmail == null) {
          errorMessage = 'Tên đăng nhập không tồn tại.';
          return false;
        }
        email = resolvedEmail;
      }

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

  Future<bool> deleteAccount() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Xóa dữ liệu Firestore của User trước khi xóa tài khoản Auth
        await FirestoreService().deleteUserData(currentUser.uid);
        await FirestoreService().deleteUsernameByUid(currentUser.uid);

        await currentUser.delete();
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Hành động này yêu cầu xác thực gần đây. Vui lòng đăng xuất và đăng nhập lại trước khi xóa tài khoản.';
      } else {
        errorMessage = _translateError(e);
      }
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}