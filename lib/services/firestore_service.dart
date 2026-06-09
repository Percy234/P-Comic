import 'package:cloud_firestore/cloud_firestore.dart';

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
}
