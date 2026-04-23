import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/services/auth_service.dart';

class ChangeEmailDialog {
  static Future<void> show(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final authService = AuthService();
    final emailController = TextEditingController(text: currentUser.email ?? '');
    final passwordController = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Change Email', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'New email',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
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
                  onPressed: isSaving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newEmail = emailController.text.trim();
                          final password = passwordController.text;
                          if (newEmail.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email and password are required.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await authService.changeEmail(
                              newEmail: newEmail,
                              currentPassword: password,
                            );
                            if (!context.mounted) return;
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(dialogContext).pop();
                            
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent. Confirm new email to finish update.'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }
}
