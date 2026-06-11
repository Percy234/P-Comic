import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách truyện yêu thích của User từ Firestore
  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    final list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      // Chuyển đổi Timestamp của Firestore sang chuỗi ISO 8601 để tương thích code cũ
      if (data['addedAt'] != null && data['addedAt'] is Timestamp) {
        data['addedAt'] = (data['addedAt'] as Timestamp).toDate().toIso8601String();
      } else {
        data['addedAt'] = DateTime.now().toIso8601String();
      }
      return data;
    }).toList();

    // Sắp xếp theo addedAt mới nhất lên đầu
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['addedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['addedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return list;
  }

  // Thêm truyện yêu thích lên Firestore
  Future<void> addFavorite({
    required String userId,
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
    String? author,
    String? genres,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(comicId)
        .set({
      'userId': userId,
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'author': author ?? 'Đang cập nhật',
      'genres': genres ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa truyện yêu thích khỏi Firestore
  Future<void> removeFavorite(String userId, String comicId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(comicId)
        .delete();
  }

  // Lấy danh sách lịch sử đọc của User từ Firestore
  Future<List<Map<String, dynamic>>> getHistories(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('histories')
        .get();

    final list = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      // Chuyển đổi Timestamp của Firestore sang chuỗi ISO 8601 để tương thích
      if (data['visitedAt'] != null && data['visitedAt'] is Timestamp) {
        data['visitedAt'] = (data['visitedAt'] as Timestamp).toDate().toIso8601String();
      } else {
        data['visitedAt'] = DateTime.now().toIso8601String();
      }
      return data;
    }).toList();

    // Sắp xếp theo visitedAt mới nhất lên đầu
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['visitedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['visitedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return list;
  }

  // Lưu lịch sử đọc truyện lên Firestore
  Future<void> addHistory({
    required String userId,
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
    required String chapterName,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('histories')
        .doc(comicId)
        .set({
      'userId': userId,
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'chapterName': chapterName,
      'visitedAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa một truyện khỏi lịch sử trên Firestore
  Future<void> removeHistory(String userId, String comicId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('histories')
        .doc(comicId)
        .delete();
  }

  // Xóa toàn bộ lịch sử đọc trên Firestore
  Future<void> clearAllHistories(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('histories')
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Lấy Stream danh sách bình luận thời gian thực của một chương truyện
  Stream<List<Map<String, dynamic>>> getCommentsStream(String roomId) {
    return _db
        .collection('chapter_comments')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        // Chuyển đổi Timestamp sang chuỗi ISO 8601
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();
    });
  }

  // Thêm bình luận vào một chương truyện trên Firestore
  Future<void> addComment({
    required String roomId,
    required String content,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Vui lòng đăng nhập để bình luận');

    final userName = user.displayName != null && user.displayName!.isNotEmpty
        ? user.displayName
        : (user.email != null && user.email!.contains('@')
            ? user.email!.split('@')[0]
            : 'Thành viên');

    final ref = _db
        .collection('chapter_comments')
        .doc(roomId)
        .collection('messages')
        .doc();

    await ref.set({
      'id': ref.id,
      'userId': user.uid,
      'userName': userName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa bình luận của một chương truyện trên Firestore
  Future<void> deleteComment({
    required String roomId,
    required String commentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Vui lòng đăng nhập để thực hiện');

    final docRef = _db
        .collection('chapter_comments')
        .doc(roomId)
        .collection('messages')
        .doc(commentId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) throw Exception('Bình luận không tồn tại');

    final data = docSnap.data();
    if (data == null || data['userId'] != user.uid) {
      throw Exception('Bạn không có quyền xóa bình luận này');
    }

    await docRef.delete();
  }

  // Xóa toàn bộ dữ liệu (Yêu thích & Lịch sử) của một User khi xóa tài khoản
  Future<void> deleteUserData(String userId) async {
    final batch = _db.batch();

    // 1. Lấy danh sách favorites
    final favSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    for (final doc in favSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Lấy danh sách histories
    final histSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('histories')
        .get();
    for (final doc in histSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Thực hiện commit toàn bộ
    await batch.commit();
  }

  // Kiểm tra tên đăng nhập đã được sử dụng chưa
  Future<bool> isUsernameTaken(String username) async {
    final normalized = username.trim().toLowerCase();
    final doc = await _db.collection('usernames').doc(normalized).get();
    return doc.exists;
  }

  // Lưu ánh xạ username sang email và uid
  Future<void> saveUsername({
    required String username,
    required String email,
    required String uid,
  }) async {
    final normalized = username.trim().toLowerCase();
    await _db.collection('usernames').doc(normalized).set({
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Lấy email liên kết với username
  Future<String?> getEmailByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final doc = await _db.collection('usernames').doc(normalized).get();
    if (doc.exists) {
      final data = doc.data();
      return data?['email'] as String?;
    }
    return null;
  }

  // Xóa tên đăng nhập giải phóng khi xóa tài khoản
  Future<void> deleteUsernameByUid(String uid) async {
    final snapshot = await _db
        .collection('usernames')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }
}
