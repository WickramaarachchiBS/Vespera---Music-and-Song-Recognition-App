import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class HomeScreenRecItem extends StatelessWidget {
  final String title;
  final String imageAsset;

  const HomeScreenRecItem({super.key, required this.title, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    // Check if imageAsset is a URL or an asset path
    final isUrl = imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 150.0,
          width: 150.0,
          margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isUrl
                ? Image.network(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.cardBackground,
                      child: const Icon(
                        Icons.playlist_play,
                        size: 60,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.cardBackground,
                      child: const Icon(
                        Icons.playlist_play,
                        size: 60,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
          ),
        ),
        Container(
          width: 150.0,
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
