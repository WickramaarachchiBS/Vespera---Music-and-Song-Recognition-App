import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/services/auth_service.dart';

class DeleteAccountDialog {
  static Future<void> show(BuildContext context) async {
    final authService = AuthService();
    final passwordController = TextEditingController();
    bool isDeleting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your account and profile data. This action cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final password = passwordController.text;
                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password is required to delete account.')),
                            );
                            return;
                          }

                          setDialogState(() => isDeleting = true);
                          try {
                            await authService.deleteAccount(currentPassword: password);
                            if (!context.mounted) return;

                            // Clear user data before navigation
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            userProvider.clearUserData();
                            
                            if (!context.mounted) return;
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(dialogContext).pop();
                            
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil('/welcome', (route) => false);
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() => isDeleting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
  }
}
