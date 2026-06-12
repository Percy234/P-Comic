import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../screens/detail_screen.dart';

import 'shimmer_placeholder.dart';

class ComicCard extends StatelessWidget {
  final Comic comic;
  final String? subtitle;
  const ComicCard({
    super.key,
    required this.comic,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(comic: comic),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.none,
          elevation: 0,
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final cardHeight = constraints.maxHeight;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              comic.imageUrl,
                              width: cardWidth,
                              height: cardHeight,
                              fit: BoxFit.cover,
                              cacheWidth: 600,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                final isLoaded = frame != null;
                                return AnimatedCrossFade(
                                  firstChild: ShimmerPlaceholder(
                                    width: cardWidth,
                                    height: cardHeight,
                                    borderRadius: BorderRadius.circular(12),
                                    enabled: !isLoaded,
                                  ),
                                  secondChild: child,
                                  crossFadeState: !isLoaded
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                comic.timeAgo,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      comic.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}