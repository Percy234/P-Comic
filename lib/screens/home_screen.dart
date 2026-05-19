import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    @override
    void initState() {
      super.initState();
      Future.microtask(() {
        context
            .read<ComicProvider>()
            .loadHomeComics();
        context
            .read<ComicProvider>()
            .loadPagedComics(1);
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P Comic'),
      ),
      body: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pagedComics.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Truyện hay',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.randomComics.length,
                    itemBuilder: (context, index) {
                      final comic = provider.randomComics[index];
                      return SizedBox(
                        width: 180,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ComicCard(comic: comic),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tất cả truyện',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.pagedComics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final comic = provider.pagedComics[index];
                    return ComicCard(comic: comic);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.currentPage > 1 ? () {
                        provider.loadPagedComics(provider.currentPage - 1);
                      } : null,
                      child: const Text('Prev'),
                    ),
                    const SizedBox(width: 20),
                    Text('Page ${provider.currentPage}'),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        provider.loadPagedComics(provider.currentPage + 1);
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}