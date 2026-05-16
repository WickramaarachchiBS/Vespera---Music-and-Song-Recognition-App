import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/helpers/app_notification.dart';
import 'package:vespera/services/playlist_service.dart';

class EditPlaylistDialog {
  static Future<void> show(
    BuildContext context, {
    required String playlistId,
    required String currentName,
    required VoidCallback onSuccess,
  }) async {
    final nameController = TextEditingController(text: currentName);
    bool isSaving = false;
    final playlistService = PlaylistService();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with icon
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundMedium,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.edit_note,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          const Text(
                            'Edit Playlist',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            'Update your playlist name',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Text field with custom styling
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundMedium,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.backgroundLight,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: nameController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter playlist name',
                                hintStyle: const TextStyle(color: AppColors.textMuted),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.playlist_add_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              maxLines: 1,
                              cursorColor: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          Row(
                            children: [
                              // Cancel button
                              Expanded(
                                child: TextButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus?.unfocus();
                                          Navigator.of(dialogContext).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: isSaving ? AppColors.textMuted.withOpacity(0.5) : AppColors.textMuted,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isSaving ? AppColors.textMuted.withOpacity(0.5) : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Save button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final newName = nameController.text.trim();

                                          if (newName.isEmpty) {
                                            AppNotification.showError(context, 'Playlist name cannot be empty');
                                            return;
                                          }

                                          if (newName == currentName) {
                                            Navigator.of(dialogContext).pop();
                                            return;
                                          }

                                          setDialogState(() => isSaving = true);

                                          try {
                                            await playlistService.updatePlaylistName(playlistId, newName);

                                            if (!context.mounted) return;
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            Navigator.of(dialogContext).pop();

                                            if (context.mounted) {
                                              AppNotification.showSuccess(context, 'Playlist renamed successfully');
                                              onSuccess();
                                            }
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            setDialogState(() => isSaving = false);
                                            AppNotification.showError(context, 'Error updating playlist: $e');
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSaving ? Colors.green.withOpacity(0.6) : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                    disabledBackgroundColor: Colors.green.withOpacity(0.5),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Save',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
