import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/services/auth_service.dart';

class ProfileEditDialog {
  static Future<void> show(BuildContext context, UserProvider userProvider) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit profile.')),
      );
      return;
    }

    final authService = AuthService();
    final nameController = TextEditingController(text: userProvider.username);
    final photoController = TextEditingController(text: userProvider.profilePicture);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Profile Photo URL',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final updatedName = nameController.text.trim();
                          final updatedPhoto = photoController.text.trim();

                          if (updatedName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username cannot be empty.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            await authService.updateUserProfile(
                              uid: uid,
                              name: updatedName,
                              profilePicture: updatedPhoto,
                            );

                            if (!context.mounted) return;
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(dialogContext).pop();

                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!context.mounted) return;

                              await userProvider.loadUserData();

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully.')),
                              );
                            });
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update profile: $e')),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    photoController.dispose();
  }
}
