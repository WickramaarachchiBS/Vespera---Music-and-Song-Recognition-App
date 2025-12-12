import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/playlist.dart';

class HomeScreenLibItem extends StatelessWidget {
  const HomeScreenLibItem({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
    required this.playlist,
    this.onTap,
  });

  final double screenHeight;
  final double screenWidth;
  final Playlist playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: (screenHeight * 0.1) - 30,
        width: (screenWidth * 0.5) - 20,
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child:
                  playlist.imageUrl.isNotEmpty
                      ? Image.network(
                        playlist.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/errorLoading.jpg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                      : Image.asset(
                        'assets/errorLoading.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: Text(
                playlist.name,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
