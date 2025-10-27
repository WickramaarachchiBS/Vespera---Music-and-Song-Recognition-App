import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class CreatePlaylistModal {
  static void show(BuildContext context, Function(String) onPlaylistCreated) {
    final TextEditingController playlistNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text('Create Playlist', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: playlistNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textMuted),
              ),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                final playlistName = playlistNameController.text.trim();
                if (playlistName.isNotEmpty) {
                  onPlaylistCreated(playlistName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
}
