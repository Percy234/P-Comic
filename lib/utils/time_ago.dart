String timeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes} phút trước';
  }

  if (difference.inDays < 1) {
    return '${difference.inHours} giờ trước';
  }

  if (difference.inDays < 30) {
    return '${difference.inDays} ngày trước';
  }

  if (difference.inDays < 365) {
    return '${difference.inDays ~/ 30} tháng trước';
  }

  return '${difference.inDays ~/ 365} năm trước';
}