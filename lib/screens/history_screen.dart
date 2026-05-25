import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HistoryProvider>().loadHistories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử')),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.histories.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử đọc'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: provider.histories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comic = provider.histories[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(12),
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://img.otruyenapi.com/uploads/comics/${comic['thumbUrl'] ?? ''}',
                    width: 56,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  comic['name'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  comic['visitedAt'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
